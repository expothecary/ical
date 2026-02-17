defmodule ICal.Serialize.Alarm do
  @moduledoc false

  alias ICal.Alarm
  alias ICal.Serialize

  def to_ics(%Alarm{} = alarm) do
    []
    |> add_trigger(alarm.trigger)
    |> add_type(alarm.type)
    |> Serialize.add_custom_properties(alarm.custom_properties)
  end

  defp add_trigger(acc, %Alarm.Trigger{} = trigger) do
    acc
    |> add_repeat(trigger.repeat)
    |> add_when(trigger.when, trigger.relative_to)
  end

  defp add_repeat(acc, value) when value < 1, do: acc
  defp add_repeat(acc, value), do: acc ++ ["REPEAT:", Serialize.to_ics(value), ?\n]

  defp add_when(acc, trigger_when, relative_to) do
    acc ++ ["TRIGGER", when_params(relative_to), ?:, Serialize.to_ics(trigger_when), ?\n]
  end

  defp add_type(acc, %Alarm.Audio{} = audio) do
    (acc ++
       ["ACTION:AUDIO\n"] ++
       Enum.map(audio.attachments, &Serialize.Attachment.to_ics/1))
    |> add_duration(audio.duration)
  end

  defp add_type(acc, %Alarm.Display{} = display) do
    (acc ++ ["ACTION:DISPLAY\n"])
    |> add_description(display.description)
  end

  defp add_type(acc, %Alarm.Email{} = email) do
    (acc ++
       ["ACTION:EMAIL\n"] ++
       Enum.map(email.attendees, &Serialize.Attendee.to_ics/1) ++
       Enum.map(email.attachments, &Serialize.Attachment.to_ics/1))
    |> add_description(email.description)
    |> add_summary(email.summary)
  end

  defp add_type(acc, %Alarm.Custom{} = custom) do
    acc ++ ["ACTION:", custom.type, ?\n]
  end

  defp add_duration(acc, nil), do: acc

  defp add_duration(acc, value) do
    acc ++ ["DURATION:", Serialize.to_ics(value), ?\n]
  end

  defp add_description(acc, value) do
    acc ++ ["DESCRIPTION:", Serialize.to_ics(value), ?\n]
  end

  defp add_summary(acc, value) do
    acc ++ ["SUMMARY:", Serialize.to_ics(value), ?\n]
  end

  defp when_params(:start), do: ";RELATED:START"
  defp when_params(:end), do: ";RELATED:END"
  defp when_params(_), do: ""
end
