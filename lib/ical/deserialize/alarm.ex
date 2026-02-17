defmodule ICalendar.Deserialize.Alarm do
  alias ICal.Alarm
  alias ICal.Deserialize

  @spec one(data :: binary, ICal.t()) :: ICal.t()
  def one(data, calendar) do
    next(data, calendar, %{}, %ICal.Alarm{})
  end

  defp next(<<>> = data, _calendar, prop_acc, alarm) do
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

  # pralarm losing other non-standard headers
  defp next(<<"X-", data::binary>>, calendar, prop_acc, alarm) do
    {data, key} = Deserialize.rest_of_key(data, "X-")
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)

    custom_entry = %{params: params, value: value}
    custom_properties = Map.put(alarm.custom_properties, key, custom_entry)
    next(data, calendar, prop_acc, %{alarm | custom_properties: custom_properties})
  end

  defp next(<<"END:VALARM", data::binary>>, _calendar, prop_acc, alarm) do
    finished(data, prop_acc, alarm)
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
    action = struct(action, props)

    # put the rest of them into custom_props, merging
    # with whatever else may have been hoovered up along the way
    custom_props =
      Map.merge(
        alarm.custom_props,
        Map.drop(props, Map.keys(action))
      )

    %{alarm | action: action, custom_props: custom_props}
  end
end
