defmodule ICalendar.Deserialize.Alarm do
  alias ICal.Alarm
  alias ICal.Deserialize

  @spec one(data :: binary, ICal.t()) :: ICal.t()
  def one(data, calendar) do
    next(data, calendar, %{attachments: [], attendees: []}, %ICal.Alarm{})
  end

  defp next(<<>> = data, _calendar, prop_acc, alarm) do
    finished(data, prop_acc, alarm)
  end

  defp next(<<"END:VALARM", data::binary>>, _calendar, prop_acc, alarm) do
    finished(data, prop_acc, alarm)
  end

  defp next(<<"ACTION", data::binary>>, calendar, prop_acc, alarm) do
    data = Deserialize.skip_params(data)
    {data, action_type} = Deserialize.rest_of_line(data)

    action =
      case action_type do
        "AUDIO" -> %Alarm.Audio{}
        "DISPLAY" -> %Alarm.Audio{}
        "EMAIL" -> %Alarm.Email{}
        type -> %Alarm.Custom{type: type}
      end

    next(data, calendar, prop_acc, %{alarm | action: action})
  end

  defp next(<<"ATTACH", data::binary>>, calendar, prop_acc, alarm) do
    {data, attachment} = Deserialize.attachment(data)
    prop_acc = %{prop_acc | attachments: prop_acc.attachments ++ [attachment]}
    next(data, calendar, prop_acc, alarm)
  end

  defp next(<<"ATTENDEE", data::binary>>, calendar, prop_acc, alarm) do
    {data, attendee} = ICal.Deserialize.Attendee.one(data)
    prop_acc = %{prop_acc | attendees: prop_acc.attendees ++ [attendee]}
    next(data, calendar, prop_acc, alarm)
  end

  defp next(<<"DESCRIPTION", data::binary>>, calendar, prop_acc, alarm) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.multi_line(data)
    prop_acc = %{prop_acc | description: value}
    next(data, calendar, prop_acc, alarm)
  end

  defp next(<<"DURATION", data::binary>>, calendar, prop_acc, alarm) do
    data = Deserialize.skip_params(data)
    {data, duration} = Deserialize.Duration.one(data)
    next(data, calendar, Map.put(prop_acc, :duration, duration), alarm)
  end

  defp next(<<"REPEAT", data::binary>>, calendar, prop_acc, alarm) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)

    repeat =
      case Integer.parse(value) do
        {integer, ""} -> integer
        _ -> 0
      end

    trigger = %{alarm.trigger | repeat: repeat}
    next(data, calendar, prop_acc, %{alarm | trigger: trigger})
  end

  defp next(<<"SUMMARY", data::binary>>, calendar, prop_acc, alarm) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.multi_line(data)
    next(data, calendar, Map.put(prop_acc, :summary, value), alarm)
  end

  defp next(<<"TRIGGER", data::binary>>, calendar, prop_acc, alarm) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)

    related =
      case Map.get(params, "RELATED") do
        "START" -> :start
        "END" -> :end
        _ -> nil
      end

    trigger_when =
      case params do
        %{"VALUE" => _} -> Deserialize.to_date(value, params, calendar)
        _ -> Deserialize.Duration.one(value)
      end

    trigger = %{alarm.trigger | relative_to: related, when: trigger_when}
    next(data, calendar, prop_acc, %{alarm | trigger: trigger})
  end

  # prevent losing other non-standard headers
  defp next(<<"X-", data::binary>>, calendar, prop_acc, alarm) do
    {data, key} = Deserialize.rest_of_key(data, "X-")
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)

    custom_entry = %{params: params, value: value}
    custom_properties = Map.put(alarm.custom_properties, key, custom_entry)
    next(data, calendar, prop_acc, %{alarm | custom_properties: custom_properties})
  end

  defp finished(data, prop_acc, alarm) do
    alarm = populate_action(prop_acc, alarm)
    {data, alarm}
  end

  defp populate_action(props, %{action: %Alarm.Custom{}} = alarm) do
    %{alarm | custom_props: Map.merge(alarm.custom_props, props)}
  end

  defp populate_action(props, %{action: action} = alarm) do
    # merge in our action-specific actions
    %{alarm | action: struct(action, props)}
  end
end
