defmodule ICal.Deserialize.Alarm do
  @moduledoc false

  alias ICal.Alarm
  alias ICal.Deserialize

  @spec one(data :: binary, ICal.t()) :: {data :: binary, nil | ICal.Alarm.t()}
  def one(data, calendar) do
    next(data, calendar, %{attachments: [], attendees: []}, %ICal.Alarm{})
  end

  defp next(<<>> = data, _calendar, properties, alarm) do
    finished(data, properties, alarm)
  end

  defp next(<<"END:VALARM", data::binary>>, _calendar, properties, alarm) do
    finished(data, properties, alarm)
  end

  defp next(<<"ACTION", data::binary>>, calendar, properties, alarm) do
    data = Deserialize.skip_params(data)
    {data, action_type} = Deserialize.value(data)

    action =
      case action_type do
        "AUDIO" -> %Alarm.Audio{}
        "DISPLAY" -> %Alarm.Display{}
        "EMAIL" -> %Alarm.Email{}
        type -> %Alarm.Custom{type: type}
      end

    next(data, calendar, properties, %{alarm | action: action})
  end

  defp next(<<"ATTACH", data::binary>>, calendar, properties, alarm) do
    {data, attachment} = Deserialize.attachment(data)
    properties = %{properties | attachments: properties.attachments ++ [attachment]}
    next(data, calendar, properties, alarm)
  end

  defp next(<<"ATTENDEE", data::binary>>, calendar, properties, alarm) do
    {data, attendee} = ICal.Deserialize.Attendee.one(data)
    properties = %{properties | attendees: properties.attendees ++ [attendee]}
    next(data, calendar, properties, alarm)
  end

  defp next(<<"DESCRIPTION", data::binary>>, calendar, properties, alarm) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.value(data)
    properties = Map.put(properties, :description, value)
    next(data, calendar, properties, alarm)
  end

  defp next(<<"DURATION", data::binary>>, calendar, properties, alarm) do
    data = Deserialize.skip_params(data)
    {data, duration} = Deserialize.Duration.one(data)
    next(data, calendar, Map.put(properties, :duration, duration), alarm)
  end

  defp next(<<"REPEAT", data::binary>>, calendar, properties, alarm) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.value(data)

    repeat = Deserialize.to_integer(value, 0)
    trigger = %{alarm.trigger | repeat: repeat}
    next(data, calendar, properties, %{alarm | trigger: trigger})
  end

  defp next(<<"SUMMARY", data::binary>>, calendar, properties, alarm) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.value(data)
    next(data, calendar, Map.put(properties, :summary, value), alarm)
  end

  defp next(<<"TRIGGER", data::binary>>, calendar, properties, alarm) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.value(data)

    related =
      case Map.get(params, "RELATED") do
        "START" -> :start
        "END" -> :end
        _ -> nil
      end

    on =
      case params do
        %{"VALUE" => _} ->
          Deserialize.to_date(value, params, calendar)

        _ ->
          {"", on} = Deserialize.Duration.one(value)
          on
      end

    trigger = %{alarm.trigger | relative_to: related, on: on}
    next(data, calendar, properties, %{alarm | trigger: trigger})
  end

  # prevent losing other non-standard headers
  defp next(<<"X-", data::binary>>, calendar, properties, alarm) do
    {data, alarm} = ICal.Deserialize.parse_custom_property(data, alarm)
    next(data, calendar, properties, alarm)
  end

  defp next(data, calendar, properties, alarm) do
    data
    |> Deserialize.skip_line()
    |> next(calendar, properties, alarm)
  end

  defp finished(data, properties, alarm) do
    alarm = populate_action(properties, alarm)
    {data, alarm}
  end

  defp populate_action(_props, %{action: %Alarm.Custom{type: nil}}) do
    nil
  end

  defp populate_action(props, %{action: %Alarm.Custom{}} = alarm) do
    %{alarm | custom_properties: Map.merge(alarm.custom_properties, props)}
  end

  defp populate_action(props, %{action: action} = alarm) do
    # merge in our action-specific actions
    %{alarm | action: struct(action, props)}
  end
end
