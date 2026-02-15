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
          by_day: [{offset :: integer, byday :: weekdays}],
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

      iex> dt = Timex.to_date({2016,8,13})
      iex> dt_end = Timex.to_date({2016, 8, 23})
      iex> event = %ICal.Event{rrule: %ICal.Recurrence{frequency: :daily}, dtstart: dt, dtend: dt}
      iex> recurrences =
            ICal.Recurrence.get_recurrences(event)
            |> Enum.to_list()
  """

  @spec stream(%Event{}) :: %Stream{}
  @spec stream(%Event{}, %Date{} | %DateTime{}) :: %Stream{}
  def stream(event, end_date \\ nil) do
    create_recurrence_stream(event, end_date, ICal.Deserialize.Recurrence.from_event(event))
  end

  # no occurences, so simply drop out
  defp create_recurrence_stream(_event, _end_date, nil), do: Stream.map([nil], fn _ -> [] end)

  defp create_recurrence_stream(event, end_date, rule) do
    reference_events =
      Map.from_struct(rule)
      |> Map.take(@supported_by_x_rrules)
      |> build_reference_events_by_x_rules(event)

    # Two types of recurrence are supported: by count or until, with until being the default
    # If not until date is specifically provided, then the end_date is used
    # An interval may be given, which alters the amount the date is shifted by
    case rule do
      %__MODULE__{frequency: frequency, count: count, interval: interval} when count != nil ->
        add_recurring_events_count(
          event,
          reference_events,
          count,
          shift_opts(frequency, interval)
        )

      %__MODULE__{frequency: frequency, until: until, interval: interval} ->
        add_recurring_events_until(
          event,
          reference_events,
          until || resolve_end_date(end_date, event),
          shift_opts(frequency, interval)
        )
    end
  end

  # The end date and the original event's dtsart must be the same sort of date
  # The user *should* take care of this, but let's not expect to much of ourselves
  # and instead ensure that they match!
  defp resolve_end_date(end_date, %{dtstart: match_to}), do: resolve_end_date(end_date, match_to)
  defp resolve_end_date(%x{} = end_date, %x{}), do: end_date
  defp resolve_end_date(nil, %Date{}), do: DateTime.to_date(DateTime.utc_now())
  defp resolve_end_date(nil, %DateTime{}), do: DateTime.utc_now()

  defp resolve_end_date(%Date{} = end_date, %DateTime{} = match_to) do
    DateTime.new(end_date, ~T[00:00:00], match_to.time_zone)
  end

  defp resolve_end_date(%DateTime{} = end_date, %Date{}), do: DateTime.to_date(end_date)

  defp shift_opts(:daily, nil), do: [days: 1]
  defp shift_opts(:daily, interval), do: [days: interval]
  defp shift_opts(:weekly, nil), do: [days: 7]
  defp shift_opts(:weekly, interval), do: [days: interval * 7]
  defp shift_opts(:monthly, nil), do: [months: 1]
  defp shift_opts(:monthly, interval), do: [months: interval]
  defp shift_opts(:yearly, nil), do: [years: 1]
  defp shift_opts(:yearly, interval), do: [years: interval]

  defp add_recurring_events_until(original_event, reference_events, until, shift_opts) do
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

  defp add_recurring_events_count(original_event, reference_events, count, shift_opts) do
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

  defp shift_event(event, shift_opts) do
    Map.merge(event, %{
      dtstart: shift_date(event.dtstart, shift_opts),
      dtend: shift_date(event.dtend, shift_opts),
      rrule: Map.put(event.rrule, :is_recurrence, true)
    })
  end

  defp shift_date(date, shift_opts) do
    case Timex.shift(date, shift_opts) do
      %Timex.AmbiguousDateTime{} = new_date ->
        new_date.after

      new_date ->
        new_date
    end
  end

  defp build_reference_events_by_x_rules(by_x_rrules, event) when by_x_rrules == %{} do
    [event]
  end

  defp build_reference_events_by_x_rules(by_x_rrules, event) do
    by_x_rrules
    |> Enum.map(fn {by_x, entries} ->
      build_reference_events_by_x_rule(event, by_x, entries)
    end)
    |> List.flatten()
  end

  defp build_reference_events_by_x_rule(event, _by_x, nil), do: [event]

  defp build_reference_events_by_x_rule(event, :by_day, entries) do
    day_values = %{
      monday: 1,
      tuesday: 2,
      wednesday: 3,
      thursday: 4,
      friday: 5,
      saturday: 6,
      sunday: 7
    }

    entries
    |> Enum.sort(fn {loffset, lday}, {roffset, rday} ->
      if loffset == roffset do
        Map.get(day_values, lday) <= Map.get(day_values, rday)
      else
        loffset <= roffset
      end
    end)
    |> Enum.map(fn {_offset, by_day} ->
      # TODO: support offsets other than the trivial case of 0
      # determine the difference between the by_day and the event's dtstart
      day_offset_for_reference = Map.get(day_values, by_day) - Timex.weekday(event.dtstart)

      %{
        event
        | dtstart: Timex.shift(event.dtstart, days: day_offset_for_reference),
          dtend: Timex.shift(event.dtend, days: day_offset_for_reference)
      }
    end)
  end

  defp remove_excluded_dates(recurrences, original_event) do
    Enum.filter(recurrences, fn event ->
      # 1. The event doesn't fall on an EXDATE
      # 2. The event is not before the original event (created as a reference)
      event.dtstart not in event.exdates &&
        compare_dates(event.dtstart, original_event.dtstart) != :lt
    end)
  end

  defp compare_dates(%Date{} = l, r), do: Date.compare(l, r)
  defp compare_dates(%DateTime{} = l, r), do: Date.compare(l, r)
end
