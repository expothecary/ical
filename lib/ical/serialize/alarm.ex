defmodule ICal.Serialize.Alarm do
  @moduledoc false

  alias ICal.Alarm
  alias ICal.Serialize

  def component(%Alarm{} = alarm) do
    [
      "BEGIN:VALARM\n",
      []
      |> add_trigger(alarm.trigger)
      |> add_action(alarm.action)
      |> Serialize.add_custom_properties(alarm.custom_properties),
      "END:VALARM\n"
    ]
  end

  defp add_trigger(acc, %Alarm.Trigger{} = trigger) do
    acc
    |> add_repeat(trigger.repeat)
    |> add_when(trigger.on, trigger.relative_to)
  end

  defp add_repeat(acc, value) when value < 1, do: acc
  defp add_repeat(acc, value), do: acc ++ ["REPEAT:", Serialize.value(value), ?\n]

  defp add_when(acc, on, relative_to) do
    acc ++ ["TRIGGER", on_params(relative_to), ?:, Serialize.value(on), ?\n]
  end

  defp add_action(acc, %Alarm.Audio{} = audio) do
    (acc ++
       ["ACTION:AUDIO\n"] ++
       Enum.map(audio.attachments, &Serialize.Attachment.property/1))
    |> add_duration(audio.duration)
  end

  defp add_action(acc, %Alarm.Display{} = display) do
    (acc ++ ["ACTION:DISPLAY\n"])
    |> add_description(display.description)
  end

  defp add_action(acc, %Alarm.Email{} = email) do
    (acc ++
       ["ACTION:EMAIL\n"] ++
       Enum.map(email.attendees, &Serialize.Attendee.property/1) ++
       Enum.map(email.attachments, &Serialize.Attachment.property/1))
    |> add_description(email.description)
    |> add_summary(email.summary)
  end

  defp add_action(acc, %Alarm.Custom{} = custom) do
    acc ++ ["ACTION:", custom.type, ?\n]
  end

  defp add_duration(acc, nil), do: acc

  defp add_duration(acc, value) do
    acc ++ ["DURATION:", Serialize.value(value), ?\n]
  end

  defp add_description(acc, value) do
    acc ++ ["DESCRIPTION:", Serialize.value(value), ?\n]
  end

  defp add_summary(acc, value) do
    acc ++ ["SUMMARY:", Serialize.value(value), ?\n]
  end

  defp on_params(:start), do: ";RELATED:START"
  defp on_params(:end), do: ";RELATED:END"
  defp on_params(_), do: ""
end
