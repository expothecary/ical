# Likely to be replaced, so ignore the many credo issues in this file for now
# credo:disable-for-this-file
defmodule ICal.Recurrence do
  @moduledoc """
  Adds support for ICal recurring.

  Events can recur by frequency, count, interval, and/or start/end date. To
  see the specific rules and examples, see `add_recurring_events/2` below.
  """

  require Logger

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
          weekday: weekday | nil
        }

  def normalize(%__MODULE__{} = recurrence) do
    %{
      recurrence
      | by_second: clamped_numbers(recurrence.by_second, 0, 59),
        by_minute: clamped_numbers(recurrence.by_minute, 0, 59),
        by_hour: clamped_numbers(recurrence.by_hour, 0, 23),
        by_day: normalize_weekdays(recurrence.by_day, recurrence.weekday),
        by_month_day: clamped_numbers(recurrence.by_month_day, -31, 31),
        by_year_day: clamped_numbers(recurrence.by_year_day, -366, 366),
        by_month: clamped_numbers(recurrence.by_month, 1, 12),
        by_set_position: clamped_numbers(recurrence.by_set_position, -366, 366),
        by_week_number: clamped_numbers(recurrence.by_week_number, -53, 53)
    }
  end

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

  def normalize_weekdays(nil, _week_start) do
    nil
  end

  def normalize_weekdays(weekdays, week_start) do
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
    |> Enum.filter(fn {_, weekday} -> Enum.member?(valid_weekdays, weekday) end)
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

  # ignore :byhour, :monthday, :byyearday, :byweekno, :bymonth for now
  @supported_by_x_rrules [:by_day]

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

  ## Event rrule options

    Event recurrance details are specified in the `rrule`. The following options
    are considered:

    - `freq`: Represents how frequently it recurs. Allowed frequencies
      are `DAILY`, `WEEKLY`, and `MONTHLY`. These can be further modified by
      the `interval` option.

    - `count` *(optional)*: Represents the number of times that it will
      recur. This takes precedence over the `end_date` parameter and the
      `until` option.

    - `interval` *(optional)*: Represents the interval at which it occurs.
      This option works in concert with `freq` above; by using the `interval`
      option, it could recur every 5 days or every 3 weeks.

    - `until` *(optional)*: Represents the end date for the recurrances.
      This takes precedence over the `end_date` parameter.

    - `by_day` *(optional)*: Represents the days of the week at which recurrences occur.

    The `freq` option is required for a valid rrule, but the others are
    optional. They may be used either individually (ex. just `freq`) or in
    concert (ex. `freq` + `interval` + `until`).

  ## Future rrule options (not yet supported)

    - `byhour` *(optional)*: Represents the hours of the day at which it occurs.
    - `byweekno` *(optional)*: Represents the week number at which it occurs.
    - `bymonthday` *(optional)*: Represents the days of the month at which it occurs.
    - `bymonth` *(optional)*: Represents the months at which it occurs.
    - `byyearday` *(optional)*: Represents the days of the year at which it occurs.

  ## Examples

      iex> dt = ~D[2016-08-13]
      iex> dt_end = ~D[2016-08-23]
      iex> event = %ICal.Event{rrule: %ICal.Recurrence{frequency: :daily}, dtstart: dt, dtend: dt}
      iex> recurrences =
            ICal.Recurrence.stream(event)
            |> Enum.to_list()
  """

  @type recurrable_component :: %{
          required(:rrule) => t() | nil,
          required(:dtstart) => Date.t() | DateTime.t() | nil,
          optional(:dtend) => Date.t() | DateTime.t() | nil
        }

  @spec stream(recurrable_component) :: Enumerable.t()
  def stream(component) do
    create_recurrence_stream(component, nil, component.rrule)
  end

  @spec stream(recurrable_component, %Date{} | %DateTime{}) :: Enumerable.t()
  def stream(component, end_date) do
    create_recurrence_stream(component, end_date, component.rrule)
  end

  # no occurences, so simply drop out, and return the component itself as the only recurrence
  defp create_recurrence_stream(_component, _end_date, nil) do
    Stream.transform([], [], fn _, acc -> {:halt, acc} end)
  end

  defp create_recurrence_stream(component, end_date, rule) do
    references =
      Map.from_struct(rule)
      |> Map.take(@supported_by_x_rrules)
      |> build_references_by_x_rules(component)

    # Two types of recurrence are supported: by count or until, with until being the default
    # If not until date is specifically provided, then the end_date is used
    # An interval may be given, which alters the amount the date is shifted by
    case rule do
      %__MODULE__{frequency: frequency, count: count, interval: interval} when count != nil ->
        # the main component counts as 1 occurance, so look for `count - 1` more
        add_recurrences_for_count(
          component,
          references,
          count - 1,
          shift_opts(frequency, interval)
        )

      %__MODULE__{frequency: frequency, until: until, interval: interval} ->
        add_recurrences_until(
          component,
          references,
          until || resolve_end_date(end_date, component),
          shift_opts(frequency, interval)
        )
    end
  end

  # The end date and the original's dtstart must be the same sort of date
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

  defp shift_opts(:daily, interval), do: [day: interval]
  defp shift_opts(:weekly, interval), do: [week: interval]
  defp shift_opts(:monthly, interval), do: [month: interval]
  defp shift_opts(:yearly, interval), do: [year: interval]

  defp add_recurrences_until(original_event, references, until, shift_opts) do
    Stream.resource(
      fn -> references end,
      fn references ->
        next_recurring_event_until(
          references,
          original_event,
          until,
          shift_opts
        )
      end,
      fn recurrences -> recurrences end
    )
  end

  defp next_recurring_event_until([], _original_event, _until, _shift_opts) do
    {:halt, []}
  end

  defp next_recurring_event_until(
         [reference_event | remaining_references],
         original_event,
         until,
         shift_opts
       ) do
    new_event = shift(reference_event, shift_opts)

    case compare(new_event.dtstart, until) do
      :gt ->
        {:halt, {[], []}}

      _ ->
        references = remaining_references ++ [new_event]

        if exclude?(new_event, original_event) do
          next_recurring_event_until(
            references,
            original_event,
            until,
            shift_opts
          )
        else
          {[new_event], references}
        end
    end
  end

  defp add_recurrences_for_count(original_event, references, count, shift_opts) do
    Stream.resource(
      fn -> {references, count} end,
      fn {references, count} ->
        next_recurring_event(references, count, original_event, shift_opts)
      end,
      fn recurrences -> recurrences end
    )
  end

  defp next_recurring_event(_references, count, _original_event, _shift_opts)
       when count < 1 do
    {:halt, {[], 0}}
  end

  defp next_recurring_event([], _count, _original_event, _shift_opts) do
    {:halt, {[], 0}}
  end

  defp next_recurring_event(
         [reference_event | remaining_references],
         count,
         original_event,
         shift_opts
       ) do
    new_event = shift(reference_event, shift_opts)
    references = remaining_references ++ [new_event]

    if exclude?(new_event, original_event) do
      next_recurring_event(
        references,
        count,
        original_event,
        shift_opts
      )
    else
      {[new_event], {references, count - 1}}
    end
  end

  defp shift(%{dtstart: starts, dtend: ends} = component, shift_opts) do
    Map.merge(component, %{
      dtstart: shift_date(starts, shift_opts),
      dtend: shift_date(ends, shift_opts)
    })
  end

  defp shift(%{dtstart: starts} = component, shift_opts) do
    Map.merge(component, %{
      dtstart: shift_date(starts, shift_opts)
    })
  end

  defp shift_date(%Date{} = date, shift_opts), do: Date.shift(date, shift_opts)
  defp shift_date(%DateTime{} = date, shift_opts), do: DateTime.shift(date, shift_opts)

  defp build_references_by_x_rules(by_x_rrules, component) when by_x_rrules == %{} do
    [component]
  end

  defp build_references_by_x_rules(by_x_rrules, component) do
    by_x_rrules
    |> Enum.map(fn {by_x, entries} ->
      build_references_by_x_rule(component, by_x, entries)
    end)
    |> List.flatten()
  end

  defp build_references_by_x_rule(component, _by_x, nil), do: [component]

  defp build_references_by_x_rule(component, :by_day, entries) do
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
      # determine the difference between the by_day and dtstart
      day_offset_for_reference = Map.get(day_values, by_day) - Date.day_of_week(component.dtstart)
      shift(component, day: day_offset_for_reference)
    end)
  end

  defp compare(%Date{} = l, r), do: Date.compare(l, r)
  defp compare(%DateTime{} = l, r), do: DateTime.compare(l, r)

  defp exclude?(recurrence, original) do
    # 1. The component doesn't fall on an EXDATE
    # 2. The recurrence is not before the original component (created as a reference)
    recurrence.dtstart in original.exdates or
      compare_dates(recurrence.dtstart, original.dtstart) == :lt
  end

  defp compare_dates(%Date{} = l, r), do: Date.compare(l, r)
  defp compare_dates(%DateTime{} = l, r), do: Date.compare(l, r)
end
