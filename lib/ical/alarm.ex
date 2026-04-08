defmodule ICal.Alarm do
  @moduledoc """
  An iCalendar Alarm
  """

  @type component_with_alarms :: %{
          required(:alarms) => [t()],
          required(:dtstart) => Date.t() | DateTime.t() | nil,
          optional(:dtend) => Date.t() | DateTime.t() | nil,
          optional(:rrule) => ICal.Recurrence.t() | nil
        }

  alias __MODULE__.{Audio, Custom, Display, Email, Trigger}

  defstruct action: %Custom{}, trigger: %Trigger{}, custom_properties: %{}

  @type t :: %__MODULE__{
          trigger: Trigger.t(),
          action: Audio.t() | Display.t() | Email.t() | Custom.t(),
          custom_properties: ICal.custom_properties()
        }

  @doc """
  Given a component with alarms, return a list of the next set of alarms with
  their trigger times, if any.
  """
  @spec next_alarms(component_with_alarms()) :: [{trigger_on :: DateTime.t(), t()}]
  def next_alarms(%{alarms: []}), do: []

  # when the event has recurrences
  def next_alarms(%{rrule: rrule} = component) when not is_nil(rrule) do
    recurrences =
      component
      |> ICal.Recurrence.stream()
      |> Enum.take(1)

    case recurrences do
      [recurrence] -> calculate_alarms(recurrence)
      _ -> []
    end
  end

  def next_alarms(event), do: calculate_alarms(event)

  @doc """
  Given a start and end date, returns when the alarm should be triggered next.

  Returns nil if it should not be triggered.
  """
  def next_activation(
        %__MODULE__{trigger: %Trigger{on: %DateTime{} = trigger_date}},
        _component
      ) do
    if_in_future(trigger_date)
  end

  def next_activation(%__MODULE__{trigger: trigger} = alarm, component) do
    trigger
    |> trigger_date(component)
    |> convert_date()
    |> triggers_on(alarm)
  end

  defp trigger_date(%Trigger{relative_to: :end}, %{dtend: end_date}), do: end_date
  defp trigger_date(_trigger, %{dtstart: start_date}), do: start_date
  defp trigger_date(_trigger, _), do: nil

  defp convert_date(%Date{} = date), do: DateTime.new(date, ~T[00:00:00], "Etc/UTC")
  defp convert_date(value), do: value

  defp triggers_on(nil, alarm), do: {nil, alarm}

  defp triggers_on(from_date, %__MODULE__{trigger: trigger}) do
    {hour, minute, second} = trigger.time
    sign = if trigger.positive, do: 1, else: -1

    from_date
    |> DateTime.shift(
      hour: sign * hour,
      minute: sign * minute,
      second: sign * second,
      day: sign * trigger.days,
      week: sign * trigger.weeks
    )
    |> if_in_future()
  end

  defp if_in_future(date) do
    case DateTime.compare(date, DateTime.utc_now()) do
      :lt -> nil
      _ -> date
    end
  end

  defp calculate_alarms(event) do
    Enum.reduce(event.alarms, [], fn alarm, acc ->
      case ICal.Alarm.next_activation(alarm, event) do
        nil -> acc
        activate_on -> [{activate_on, alarm} | acc]
      end
    end)
  end
end
