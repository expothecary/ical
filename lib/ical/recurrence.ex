# Likely to be replaced, so ignore the many credo issues in this file for now
# credo:disable-for-this-file
defmodule ICal.Recurrence do
  @moduledoc """
  Adds support for recurring events.

  Events can recur by frequency, count, interval, and/or start/end date. To
  see the specific rules and examples, see `add_recurring_events/2` below.
  """

  require Logger

  alias ICal.Event

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
    :weekday,
    frequency: :daily,
    interval: 1
  ]

  @type frequency :: :secondly | :minutely | :hourly | :daily | :weekly | :monthly | :yearly
  @type weekdays :: :monday | :tuesday | :wednesday | :thursday | :friday | :saturday | :sunday
  @type t :: %__MODULE__{
          frequency: frequency,
          until: DateTime.t() | nil,
          count: integer,
          interval: integer,
          by_second: [non_neg_integer],
          by_minute: [non_neg_integer],
          by_hour: [non_neg_integer],
          by_day: [non_neg_integer],
          by_month_day: [non_neg_integer],
          by_year_day: [non_neg_integer],
          by_month: [non_neg_integer],
          by_week_number: [non_neg_integer],
          by_set_position: [non_neg_integer],
          weekday: weekdays
        }

  # ignore :byhour, :monthday, :byyearday, :byweekno, :bymonth for now
  @supported_by_x_rrules [:by_day]

  @doc """
  Given an event, return a stream of recurrences for that event.

  Warning: this may create a very large sequence of event recurrences.

  ## Parameters

    - `event`: The event that may contain an rrule. See `ICal.Event`.

    - `end_date` *(optional)*: A date time that represents the fallback end date
      for a recurring event. This value is only used when the options specified
      in rrule result in an infinite recurrance (ie. when neither `count` nor
      `until` is set). If no end_date is set, it will default to
      `DateTime.utc_now()`.

  ## Event rrule options

    Event recurrance details are specified in the `rrule`. The following options
    are considered:

    - `freq`: Represents how frequently the event recurs. Allowed frequencies
      are `DAILY`, `WEEKLY`, and `MONTHLY`. These can be further modified by
      the `interval` option.

    - `count` *(optional)*: Represents the number of times that an event will
      recur. This takes precedence over the `end_date` parameter and the
      `until` option.

    - `interval` *(optional)*: Represents the interval at which events occur.
      This option works in concert with `freq` above; by using the `interval`
      option, an event could recur every 5 days or every 3 weeks.

    - `until` *(optional)*: Represents the end date for a recurring event.
      This takes precedence over the `end_date` parameter.

    - `by_day` *(optional)*: Represents the days of the week at which events occur.

    The `freq` option is required for a valid rrule, but the others are
    optional. They may be used either individually (ex. just `freq`) or in
    concert (ex. `freq` + `interval` + `until`).

  ## Future rrule options (not yet supported)

    - `byhour` *(optional)*: Represents the hours of the day at which events occur.
    - `byweekno` *(optional)*: Represents the week number at which events occur.
    - `bymonthday` *(optional)*: Represents the days of the month at which events occur.
    - `bymonth` *(optional)*: Represents the months at which events occur.
    - `byyearday` *(optional)*: Represents the days of the year at which events occur.

  ## Examples

      iex> dt = Timex.Date.from({2016,8,13})
      iex> dt_end = Timex.Date.from({2016, 8, 23})
      iex> event = %ICal.Event{rrule:%{frequency: :daily}, dtstart: dt, dtend: dt}
      iex> recurrences =
            ICal.Recurrence.get_recurrences(event)
            |> Enum.to_list()

  """
  @spec get_recurrences(%Event{}) :: %Stream{}
  @spec get_recurrences(%Event{}, %DateTime{}) :: %Stream{}
  def get_recurrences(event, end_date \\ DateTime.utc_now()) do
    get_recurrences(event, end_date, ICal.Deserialize.Recurrence.from_event(event))
  end

  def get_recurrences(_event, _end_date, nil), do: Stream.map([nil], fn _ -> [] end)

  def get_recurrences(event, end_date, rule) do
    by_x_rrules = Map.take(Map.from_struct(rule), @supported_by_x_rrules)

    reference_events =
      if Enum.empty?(by_x_rrules) do
        [event]
      else
        # There supported by_x modifiers in the rrule, build reference events based on them
        # The invalid reference events are removed later
        build_reference_events_by_x_rules(event, by_x_rrules)
      end

    case rule do
      %{frequency: :daily, count: count, interval: interval} when count != nil ->
        add_recurring_events_count(event, reference_events, count, days: interval || 1)

      %{frequency: :daily, until: until, interval: interval} when until != nil ->
        add_recurring_events_until(event, reference_events, until, days: interval || 1)

      %{frequency: :daily, interval: interval} ->
        add_recurring_events_until(event, reference_events, end_date, days: interval || 1)

      %{frequency: :weekly, until: until, interval: interval} when until != nil ->
        add_recurring_events_until(event, reference_events, until, days: (interval || 1) * 7)

      %{frequency: :weekly, count: count} when count != nil ->
        add_recurring_events_count(event, reference_events, count, days: 7)

      %{frequency: :weekly, interval: interval} ->
        add_recurring_events_until(event, reference_events, end_date, days: (interval || 1) * 7)

      %{frequency: :monthly, count: count, interval: interval} when count != nil ->
        add_recurring_events_count(event, reference_events, count, months: interval || 1)

      %{frequency: :monthly, until: until, interval: interval} when until != nil ->
        add_recurring_events_until(event, reference_events, until, months: interval || 1)

      %{frequency: :monthly, interval: interval} ->
        add_recurring_events_until(event, reference_events, end_date, months: interval)

      %{frequency: :monthly} ->
        add_recurring_events_until(event, reference_events, end_date, months: 1)

      %{frequency: :yearly, count: count, interval: interval} when count != nil ->
        add_recurring_events_count(event, reference_events, count, years: interval || 1)

      %{frequency: :yearly, until: until, interval: interval} when until != nil ->
        add_recurring_events_until(event, reference_events, until, years: interval || 1)

      %{frequency: :yearly, interval: interval} when interval != nil ->
        add_recurring_events_until(event, reference_events, end_date, years: interval)

      %{frequency: :yearly} ->
        add_recurring_events_until(event, reference_events, end_date, years: 1)

      %{frequency: unsupported} ->
        Logger.warning("Recurrence for frequency of #{unsupported} has not been implemented.")
        Stream.map([nil], fn _ -> [] end)
    end
  end

  def add_recurring_events_until(original_event, reference_events, until, shift_opts) do
    Stream.resource(
      fn -> [reference_events] end,
      fn acc_events ->
        # Use the previous batch of the events as the reference for the next batch
        [prev_event_batch | _] = acc_events

        case prev_event_batch do
          [] ->
            {:halt, acc_events}

          prev_event_batch ->
            new_events =
              Enum.map(prev_event_batch, fn reference_event ->
                new_event = shift_event(reference_event, shift_opts)

                case Timex.compare(new_event.dtstart, until) do
                  1 -> []
                  _ -> [new_event]
                end
              end)
              |> List.flatten()

            {remove_excluded_dates(new_events, original_event), [new_events | acc_events]}
        end
      end,
      fn recurrences ->
        recurrences
      end
    )
  end

  def add_recurring_events_count(original_event, reference_events, count, shift_opts) do
    Stream.resource(
      fn -> {[reference_events], count} end,
      fn {acc_events, count} ->
        # Use the previous batch of the events as the reference for the next batch
        [prev_event_batch | _] = acc_events

        case prev_event_batch do
          [] ->
            {:halt, acc_events}

          prev_event_batch ->
            new_events =
              Enum.map(prev_event_batch, fn reference_event ->
                new_event = shift_event(reference_event, shift_opts)

                if count > 1 do
                  [new_event]
                else
                  []
                end
              end)
              |> List.flatten()

            {remove_excluded_dates(new_events, original_event),
             {[new_events | acc_events], count - 1}}
        end
      end,
      fn recurrences ->
        recurrences
      end
    )
  end

  def shift_event(event, shift_opts) do
    Map.merge(event, %{
      dtstart: shift_date(event.dtstart, shift_opts),
      dtend: shift_date(event.dtend, shift_opts),
      rrule: Map.put(event.rrule, :is_recurrence, true)
    })
  end

  def shift_date(date, shift_opts) do
    case Timex.shift(date, shift_opts) do
      %Timex.AmbiguousDateTime{} = new_date ->
        new_date.after

      new_date ->
        new_date
    end
  end

  def build_reference_events_by_x_rules(event, by_x_rrules) do
    IO.inspect(by_x_rrules, label: "x rules are")

    by_x_rrules
    |> Enum.map(fn {by_x, entries} ->
      build_reference_events_by_x_rule(event, by_x, entries)
    end)
    |> List.flatten()
  end

  @day_values %{
    sunday: 0,
    monday: 1,
    tuesday: 2,
    wednesday: 3,
    thursday: 4,
    friday: 5,
    saturday: 6
  }

  def build_reference_events_by_x_rule(event, _by_x, nil), do: [event]

  def build_reference_events_by_x_rule(event, :by_day, entries) do
    IO.inspect(entries, label: "x rules are")

    Enum.map(entries, fn by_day ->
      # determine the difference between the by_day and the event's dtstart
      IO.inspect(Map.get(@day_values, by_day), label: "OFFET FOR #{by_day}")
      day_offset_for_reference = Map.get(@day_values, by_day) - Timex.weekday(event.dtstart)

      %{
        event
        | dtstart: Timex.shift(event.dtstart, days: day_offset_for_reference),
          dtend: Timex.shift(event.dtend, days: day_offset_for_reference)
      }
    end)
  end

  def remove_excluded_dates(recurrences, original_event) do
    Enum.filter(recurrences, fn new_event ->
      # Make sure new event doesn't fall on an EXDATE
      falls_on_exdate = not is_nil(new_event) and new_event.dtstart in new_event.exdates

      #  This removes any events which were created as references
      is_invalid_reference_event =
        DateTime.compare(new_event.dtstart, original_event.dtstart) == :lt

      !falls_on_exdate &&
        !is_invalid_reference_event
    end)
  end
end
