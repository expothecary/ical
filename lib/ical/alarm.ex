defmodule ICal.Alarm do
  @moduledoc """
  An iCalendar Alarm
  """
  @callback next_alarms(event :: ICal.Event.t() | ICal.Todo.t()) :: Enumerable.t(ICal.Alarm.t())
  alias __MODULE__.{Audio, Custom, Display, Email, Trigger}

  defstruct action: %Custom{}, trigger: %Trigger{}, custom_properties: %{}

  @type t :: %__MODULE__{
          trigger: Trigger.t(),
          action: Audio.t() | Display.t() | Email.t() | Custom.t(),
          custom_properties: ICal.custom_properties()
        }

  @doc "Given a start and end date, returns when the alarm should be triggered"
  def activate_on(
        %__MODULE__{trigger: %Trigger{on: %DateTime{} = trigger_date}} = alarm,
        _component
      ) do
    {if_in_future(trigger_date), alarm}
  end

  def activate_on(%__MODULE__{trigger: trigger} = alarm, component) do
    trigger
    |> trigger_date(component)
    |> convert_date()
    |> triggers_on(alarm)
  end

  defp trigger_date(%Trigger{relative_to: :end}, %{dtend: end_date}), do: end_date
  defp trigger_date(_trigger, %{dtstart: start_date}), do: start_date

  defp convert_date(%Date{} = date), do: DateTime.new(date, ~T[00:00:00], "Etc/UTC")
  defp convert_date(value), do: value

  defp triggers_on(nil, alarm), do: {nil, alarm}

  defp triggers_on(from_date, %__MODULE__{trigger: trigger} = alarm) do
    {hour, minute, second} = trigger.time
    sign = if trigger.positive, do: 1, else: -1

    trigger_date =
      from_date
      |> DateTime.shift(
        hour: sign * hour,
        minute: sign * minute,
        second: sign * second,
        day: sign * trigger.days,
        week: sign * trigger.weeks
      )

    {if_in_future(trigger_date), alarm}
  end

  defp if_in_future(date) do
    case Timex.compare(date, DateTime.utc_now()) do
      1 -> nil
      _ -> date
    end
  end
end
