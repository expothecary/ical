# Likely to be replaced, so ignore the many credo issues in this file for now
# credo:disable-for-this-file
defmodule ICal.Recurrence do
  @moduledoc """
  Adds support for ICal recurring.

  Events can recur by frequency, count, interval, and/or start/end date. To
  see the specific rules and examples, see `add_recurring_events/2` below.
  """

  require Logger
  alias ICal.Recurrence.{Generate, State}

  defstruct [
    :until,
    :count,
    :by_second,
    :by_minute,
    :by_hour,
    :by_day,
    :by_month_day,
    :by_year_day,
    :by_month,
    :by_set_position,
    :by_week_number,
    week_start_day: :default,
    frequency: :daily,
    interval: 1
  ]

  @type frequency :: :secondly | :minutely | :hourly | :daily | :weekly | :monthly | :yearly
  @type weekday :: :monday | :tuesday | :wednesday | :thursday | :friday | :saturday | :sunday
  @type t :: %__MODULE__{
          frequency: frequency,
          until: DateTime.t() | nil,
          count: non_neg_integer,
          interval: non_neg_integer,
          by_second: [non_neg_integer] | nil,
          by_minute: [non_neg_integer] | nil,
          by_hour: [non_neg_integer] | nil,
          by_day: [{offset :: integer, byday :: weekday}] | nil,
          by_month_day: [non_neg_integer] | nil,
          by_year_day: [non_neg_integer] | nil,
          by_month: [non_neg_integer] | nil,
          by_week_number: [non_neg_integer] | nil,
          by_set_position: [non_neg_integer] | nil,
          week_start_day: weekday | :default
        }

  def normalize(%__MODULE__{} = recurrence) do
    %{
      recurrence
      | by_second: clamped_numbers(recurrence.by_second, 0, 59),
        by_minute: clamped_numbers(recurrence.by_minute, 0, 59),
        by_hour: clamped_numbers(recurrence.by_hour, 0, 23),
        by_day: normalize_weekdays(recurrence.by_day, recurrence.week_start_day),
        by_month_day: clamped_numbers(recurrence.by_month_day, -31, 31),
        by_year_day: clamped_numbers(recurrence.by_year_day, -366, 366),
        by_month: clamped_numbers(recurrence.by_month, 1, 12),
        by_set_position: clamped_numbers(recurrence.by_set_position, -366, 366),
        by_week_number: clamped_numbers(recurrence.by_week_number, -53, 53),
        count: nil_or_positive(recurrence.count),
        interval: positive(recurrence.interval, 1)
    }
  end

  def from_ics(<<"RRULE", data::binary>>) do
    data = ICal.Deserialize.skip_params(data)
    {_data, values} = ICal.Deserialize.param_list(data)
    ICal.Deserialize.Recurrence.from_params(values)
  end

  defp nil_or_positive(value) when is_integer(value) and value > 0, do: value
  defp nil_or_positive(_), do: nil

  defp positive(value, _default) when is_integer(value) and value > 0, do: value
  defp positive(_, default), do: default

  defp clamped_numbers(nil, _min, __max), do: nil

  defp clamped_numbers(numbers, min, max) do
    numbers
    |> Enum.sort()
    |> Enum.uniq()
    |> Enum.reduce(
      [],
      fn number, acc ->
        case number do
          0 when min == 0 ->
            acc ++ [0]

          number when is_number(number) and number != 0 and number <= max and number >= min ->
            acc ++ [number]

          _ ->
            acc
        end
      end
    )
  end

  defp normalize_weekdays(nil, _week_start) do
    nil
  end

  defp normalize_weekdays(weekdays, week_start) do
    valid_weekdays = [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]

    weekday_order =
      if week_start == nil do
        valid_weekdays
      else
        index = Enum.find_index(valid_weekdays, fn wk -> wk == week_start end) || 0
        {l, r} = Enum.split(valid_weekdays, max(0, index))
        r ++ l
      end
      |> Enum.with_index()
      |> Enum.into(%{})

    weekdays
    |> Enum.uniq()
    |> Enum.sort(fn {loffset, l}, {roffset, r} ->
      if loffset == roffset do
        Map.get(weekday_order, l) < Map.get(weekday_order, r)
      else
        l_is_neg = loffset < 0
        r_is_neg = roffset < 0

        if l_is_neg == r_is_neg do
          loffset < roffset
        else
          r_is_neg
        end
      end
    end)
  end

  @doc """
  Given a component with a recurrence rule, return a stream of recurrences for it.

  Warning: this may create a very large sequence of recurrences.

  ## Parameters

    - `component`: The ICal component (e.g. event or todo) that may contain an rrule. See `ICal.Event`.

    - `end_date` *(optional)*: A date time that represents the fallback end date
      for recurrence. This value is only used when the options specified
      in the rrule result in an infinite recurrance (ie. when neither `count` nor
      `until` is set). If no end_date is set, it will default to
      `DateTime.utc_now()`.

  ## Examples

      iex> dt = ~D[2016-08-13]
      iex> dt_end = ~D[2016-08-23]
      iex> event = %ICal.Event{rrule: %ICal.Recurrence{frequency: :daily}, dtstart: dt, dtend: dt}
      iex> recurrences =
            ICal.Recurrence.stream(event)
            |> Enum.to_list()
  """

  @type recurrable_component :: %{}

  @spec stream(recurrable_component, nil | %Date{} | %DateTime{}) :: Enumerable.t()
  def stream(component, end_date \\ nil) do
    create_recurrence_stream(component, end_date)
  end

  # no occurences, so simply drop out, and return the component itself as the only recurrence
  defp create_recurrence_stream(%{rrule: rule, dtstart: start_date}, _end_date)
       when is_nil(rule) or is_nil(start_date) do
    Stream.transform([], [], fn _, acc -> {:halt, acc} end)
  end

  defp create_recurrence_stream(%{rrule: rule, dtstart: start_date, exdates: exclude_dates}, end_date) do
    Stream.resource(
      fn -> {[], Generate.init(rule, start_date, end_date, exclude_dates)} end,
      fn state -> next_recurring_event(state) end,
      fn state -> state end
    )
  end

  defp next_recurring_event({[], %State{limit: :reached}} = state) do
    {:halt, state}
  end

  defp next_recurring_event({[], %State{} = generate_state}) do
    generate_state
    |> Generate.one_set()
    |> next_recurring_event()
  end

  defp next_recurring_event({recurrences, %State{} = generate_state}) do
    {recurrences, {[], generate_state}}
  end
end
