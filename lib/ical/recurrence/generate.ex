defmodule ICal.Recurrence.Generate do
  @moduledoc false

  require Logger
  alias ICal.Recurrence.State

  @fruitless_search_start_count 0
  @max_fruitless_search_depth 1000

  defguard has_some(x) when is_list(x) and x != []
  defguard has_none(x) when not has_some(x)

  @type error_reasons :: :search_exhaustion | :no_defined_limit

  @spec init(
          ICal.Recurrence.t(),
          start_date :: ICal.Recurrence.recurrence_date(),
          options :: [ICal.Recurrence.stream_option()]
        ) ::
          State.t()
  def init(rule, start_date, options \\ []) do
    other_recurrences =
      options
      |> resolve_option(:other_recurrences, [])
      |> Enum.sort(&compare_recurrences/2)

    %State{
      earliest_date: start_date,
      start_date: start_date,
      interval: rule_interval(rule),
      modifiers: rule_modifiers(rule),
      rule: rule,
      exclude_dates: resolve_option(options, :exclude_dates, []),
      other_recurrences: other_recurrences
    }
    |> add_rule_limits(rule, Keyword.get(options, :end_date))
  end

  @spec all(ICal.Recurrence.t(), starting_from :: ICal.Recurrence.recurrence_date()) ::
          {:ok, [ICal.Recurrence.recurrence_date()]}
          | {:error, error_reasons, [ICal.Recurrence.recurrence_date()]}
  def all(rule, start_date) do
    init(rule, start_date)
    |> generate_all()
  end

  @spec one_set(State.t()) :: {[ICal.Recurrence.recurrence_date()], State.t()}
  def one_set(%State{} = state) do
    generate_set(state)
  end

  defp resolve_option(options, key, default) do
    case Keyword.get(options, key) do
      nil -> default
      value -> value
    end
  end

  defp rule_interval(%ICal.Recurrence{frequency: :yearly, interval: interval}) do
    {:date, [year: interval]}
  end

  defp rule_interval(%ICal.Recurrence{frequency: :monthly, interval: interval}) do
    {:date, [month: interval]}
  end

  defp rule_interval(%ICal.Recurrence{frequency: :weekly, interval: interval}) do
    {:date, [week: interval]}
  end

  defp rule_interval(%ICal.Recurrence{frequency: :daily, interval: interval}) do
    {:date, [day: interval]}
  end

  defp rule_interval(%ICal.Recurrence{frequency: :hourly, interval: interval}) do
    {:time, [hour: interval]}
  end

  defp rule_interval(%ICal.Recurrence{frequency: :minutely, interval: interval}) do
    {:time, [minute: interval]}
  end

  defp rule_interval(%ICal.Recurrence{frequency: :secondly, interval: interval}) do
    {:time, [second: interval]}
  end

  defp rule_modifiers(%ICal.Recurrence{frequency: :yearly} = rule) do
    week_number_application =
      if has_some(rule.by_month), do: :limit, else: :expand

    year_day_appliaction =
      if has_some(rule.by_month) or has_some(rule.by_week_number), do: :limit, else: :expand

    by_day_application =
      cond do
        has_some(rule.by_year_day) -> :limit
        has_some(rule.by_month_day) -> :limit
        has_some(rule.by_week_number) -> :limit
        has_some(rule.by_month) -> :expand_month
        true -> :expand_year
      end

    [
      {:by_month, :expand},
      {:by_week_number, week_number_application},
      {:by_year_day, year_day_appliaction},
      {:by_month_day, :expand},
      {:by_day, by_day_application},
      {:by_hour, :expand},
      {:by_minute, :expand},
      {:by_second, :expand},
      {:by_set_position, :limit}
    ]
  end

  defp rule_modifiers(%ICal.Recurrence{frequency: :monthly} = rule) do
    by_day_application = if has_some(rule.by_month_day), do: :limit, else: :expand_month

    [
      {:by_month, :limit},
      {:by_month_day, :expand},
      {:by_day, by_day_application},
      {:by_hour, :expand},
      {:by_minute, :expand},
      {:by_second, :expand},
      {:by_set_position, :limit}
    ]
  end

  defp rule_modifiers(%ICal.Recurrence{frequency: :weekly}) do
    [
      {:by_month, :limit},
      {:by_day, :expand_week},
      {:by_hour, :expand},
      {:by_minute, :expand},
      {:by_second, :expand},
      {:by_set_position, :limit}
    ]
  end

  defp rule_modifiers(%ICal.Recurrence{frequency: :daily}) do
    [
      {:by_month, :limit},
      {:by_month_day, :limit},
      {:by_day, :limit},
      {:by_hour, :expand},
      {:by_minute, :expand},
      {:by_second, :expand},
      {:by_set_position, :limit}
    ]
  end

  defp rule_modifiers(%ICal.Recurrence{frequency: :hourly}) do
    [
      {:by_month, :limit},
      {:by_year_day, :limit},
      {:by_month_day, :limit},
      {:by_day, :limit},
      {:by_hour, :limit},
      {:by_minute, :expand},
      {:by_set_position, :limit}
    ]
  end

  defp rule_modifiers(%ICal.Recurrence{frequency: :minutely}) do
    [
      {:by_month, :limit},
      {:by_year_day, :limit},
      {:by_month_day, :limit},
      {:by_day, :limit},
      {:by_hour, :limit},
      {:by_minute, :limit},
      {:by_second, :expand},
      {:by_set_position, :limit}
    ]
  end

  defp rule_modifiers(%ICal.Recurrence{frequency: :secondly}) do
    [
      {:by_month, :limit},
      {:by_year_day, :limit},
      {:by_month_day, :limit},
      {:by_day, :limit},
      {:by_hour, :limit},
      {:by_minute, :limit},
      {:by_set_position, :limit}
    ]
  end

  defp generate_all(state) do
    generate_all(state, [])
  end

  defp generate_all(%{limit: nil}, acc) do
    {:error, :no_defined_limit, acc}
  end

  defp generate_all(%{limit: limit}, acc) when is_integer(limit) and limit < 1 do
    {:ok, acc}
  end

  defp generate_all(state, acc) do
    {recurrences, new_state} = generate_set(state)

    if new_state.limit == :reached do
      {:ok, acc ++ recurrences}
    else
      generate_all(new_state, acc ++ recurrences)
    end
  end

  defp generate_set(%{fruitless_searches: fruitless_searches, rule: rule} = state)
       when fruitless_searches > @max_fruitless_search_depth do
    Logger.warning("Could not find all recurrences of #{inspect(rule)} due to search exhaustion")
    {[], %{state | limit: :reached}}
  end

  defp generate_set(%State{} = state) do
    recurrences =
      [state.start_date]
      |> apply_all_modifiers(state)
      |> exclude(state)

    new_state = %{state | start_date: shift_interval(state.start_date, state.interval)}
    update_limit(recurrences, new_state)
  end

  defp apply_all_modifiers(recurrences, %{modifiers: modifiers, rule: rule}) do
    Enum.reduce(modifiers, recurrences, fn modifier, acc ->
      apply_modifier(modifier, rule, acc)
      |> Enum.filter(&date_valid?/1)
      |> Enum.sort(&compare_recurrences/2)
    end)
  end

  defp date_valid?(%Date{} = date) do
    Calendar.ISO.valid_date?(date.year, date.month, date.day)
  end

  defp date_valid?(%DateTime{} = datetime) do
    Calendar.ISO.valid_date?(datetime.year, datetime.month, datetime.day) and
      Calendar.ISO.valid_time?(datetime.hour, datetime.minute, datetime.second, {0, 0})
  end

  defp compare_recurrences(%DateTime{} = l, r), do: DateTime.compare(l, r) == :lt
  defp compare_recurrences(%Date{} = l, r), do: Date.compare(l, r) == :lt

  defp apply_modifier({:by_month, :expand}, %{by_month: months}, acc) when has_some(months) do
    Enum.reduce(acc, [], fn recurrence, acc ->
      Enum.reduce(months, acc, fn month, acc ->
        [%{recurrence | month: month} | acc]
      end)
    end)
  end

  defp apply_modifier({:by_month, :limit}, %{by_month: months}, acc) when has_some(months) do
    Enum.filter(acc, fn recurrence ->
      Enum.member?(months, recurrence.month)
    end)
  end

  defp apply_modifier({:by_week_number, :expand}, %{by_week_number: weeks}, acc)
       when has_some(weeks) do
    Enum.reduce(acc, [], fn recurrence, acc ->
      Enum.reduce(weeks, acc, fn week, acc ->
        {first, last} = week_number_bookends(recurrence, week)

        acc ++ range(first, last, recurrence)
      end)
    end)
  end

  defp apply_modifier({:by_week_number, :limit}, %{by_week_number: weeks}, acc)
       when has_some(weeks) do
    Enum.filter(acc, fn recurrence ->
      Enum.find(weeks, fn week ->
        {week_start, week_end} = week_number_bookends(recurrence, week)
        is_between_inclusive(week_start, recurrence, week_end)
      end) != nil
    end)
  end

  defp apply_modifier({:by_year_day, :expand}, %{by_year_day: year_days}, acc)
       when has_some(year_days) do
    Enum.uniq_by(acc, fn recurrence -> recurrence.year end)
    |> Enum.reduce([], fn recurrence, acc ->
      first_of_jan = %{recurrence | month: 1, day: 1}

      Enum.reduce(year_days, acc, fn day_of_year, acc ->
        [shift_date(first_of_jan, day: day_of_year - 1) | acc]
      end)
    end)
  end

  defp apply_modifier({:by_year_day, :limit}, %{by_year_day: year_days}, acc)
       when has_some(year_days) do
    Enum.filter(acc, fn recurrence ->
      Enum.member?(year_days, Date.day_of_year(recurrence))
    end)
  end

  defp apply_modifier({:by_month_day, :expand}, %{by_month_day: month_days}, acc)
       when has_some(month_days) do
    Enum.reduce(acc, [], fn recurrence, acc ->
      Enum.reduce(month_days, acc, fn month_day, acc ->
        first = %{recurrence | day: 1}

        date =
          if month_day > 0 do
            shift_date(first, day: month_day - 1)
          else
            end_day = days_in_month(recurrence)
            shift_date(first, day: end_day + month_day)
          end

        if date.month == recurrence.month do
          [date | acc]
        else
          acc
        end
      end)
    end)
  end

  defp apply_modifier({:by_month_day, :limit}, %{by_month_day: month_days}, acc)
       when has_some(month_days) do
    Enum.filter(acc, fn recurrence ->
      Enum.member?(month_days, recurrence.day)
    end)
  end

  defp apply_modifier({:by_day, :expand_year}, %{by_day: weekdays}, acc)
       when has_some(weekdays) do
    Enum.reduce(acc, [], fn recurrence, acc ->
      Enum.reduce(weekdays, acc, fn
        {offset, weekday}, acc when offset >= 0 ->
          order = weekday_order()
          first_of_jan = %{recurrence | month: 1, day: 1}
          first_week_day = order[weekday(first_of_jan)]
          weekday_order = order[weekday]
          # calculate when the first of this day occurs in the month
          first =
            case first_week_day - weekday_order do
              diff when diff < 0 -> diff + 7
              diff -> 8 - diff
            end

          # first day of the year this weekday appears
          first_occurance = %{first_of_jan | day: first}

          # having found the first day in the year, move forward offset less one
          # more weeks
          offset = max(0, offset - 1)

          next = shift_date(first_occurance, week: offset)

          if next.year == recurrence.year do
            [next | acc]
          else
            acc
          end

        {offset, weekday}, acc ->
          order = weekday_order()
          dec_31 = %{recurrence | month: 12, day: 31}
          last_week_day = order[weekday(dec_31)]
          weekday_order = order[weekday]

          # the last day in the month for this weekday
          last =
            case weekday_order - last_week_day do
              diff when diff < 1 -> 31 + diff
              diff -> 24 + diff
            end

          # last day in the year this weekday appears
          last_occurance = %{dec_31 | day: last}

          next = shift_date(last_occurance, week: offset + 1)

          if next.year == recurrence.year do
            [next | acc]
          else
            acc
          end
      end)
    end)
  end

  defp apply_modifier({:by_day, :expand_month}, %{by_day: weekdays}, acc)
       when has_some(weekdays) do
    Enum.reduce(acc, [], fn recurrence, acc ->
      order = weekday_order()

      first_week_day = order[weekday(%{recurrence | day: 1})]

      Enum.reduce(
        weekdays,
        acc,
        fn
          {0, weekday}, acc ->
            weekday_order = order[weekday]

            # calculate when the first of this day occurs in the month
            # if the weekday order is before the first weekday
            # of the month, then it appears one week later minus the difference
            # if the weekday order is after, then it's just the diff + 1 days in
            first =
              case first_week_day - weekday_order do
                diff when diff <= 0 -> abs(diff) + 1
                diff -> 8 - diff
              end

            acc ++ generate_all_weekdays_in_month([%{recurrence | day: first}])

          {offset, weekday}, acc when offset > 0 ->
            first_day = %{recurrence | day: 1}
            month_starts = order[weekday(first_day)]
            days_in_month = days_in_month(recurrence)
            shift_days = Integer.mod(order[weekday] - month_starts, 7) + 7 * (offset - 1)

            if shift_days >= days_in_month do
              acc
            else
              [shift_date(first_day, day: shift_days) | acc]
            end

          {offset, weekday}, acc ->
            last_day = %{recurrence | day: days_in_month(recurrence)}
            month_ends = order[weekday(last_day)]

            # shift by the difference between the month end weekday and the target weekday,
            # plus one week per additional offset
            shift_days =
              Integer.mod(month_ends - order[weekday], 7) + 7 * (abs(offset) - 1)

            if shift_days >= last_day.day do
              acc
            else
              [shift_date(last_day, day: -shift_days) | acc]
            end
        end
      )
    end)
  end

  defp apply_modifier(
         {:by_day, :expand_week},
         %{by_day: weekdays, week_start_day: week_start_day},
         acc
       )
       when has_some(weekdays) do
    Enum.reduce(acc, [], fn recurrence, acc ->
      order = weekday_order()
      first_week_day = beginning_of_week(recurrence, week_start_day)
      week_start_ordinal = order[weekday(first_week_day)]

      Enum.reduce(
        weekdays,
        acc,
        fn {_, weekday}, acc ->
          # mod by 7 in case of negative difference
          shift_days = Integer.mod(order[weekday] - week_start_ordinal, 7)
          [shift_date(first_week_day, day: shift_days) | acc]
        end
      )
    end)
  end

  defp apply_modifier({:by_day, :limit}, %{by_day: weekdays}, acc) when has_some(weekdays) do
    Enum.filter(acc, fn recurrence ->
      target = weekday(recurrence)
      Enum.find(weekdays, fn {_, allowed_day} -> allowed_day == target end) != nil
    end)
  end

  defp apply_modifier({:by_hour, :expand}, %{by_hour: hours}, acc) when has_some(hours) do
    Enum.reduce(acc, [], fn recurrence, acc ->
      Enum.reduce(
        hours,
        acc,
        fn hour, acc ->
          date =
            case recurrence do
              %Date{} = date -> DateTime.new!(date, Time.new!(hour, 0, 0))
              %DateTime{} = date -> %{date | hour: hour}
            end

          [date | acc]
        end
      )
    end)
  end

  defp apply_modifier({:by_hour, :limit}, %{by_hour: hours}, acc) when has_some(hours) do
    Enum.filter(acc, fn recurrence ->
      case recurrence do
        %DateTime{hour: hour} -> Enum.member?(hours, hour)
        _ -> false
      end
    end)
  end

  defp apply_modifier({:by_minute, :expand}, %{by_minute: minutes}, acc) when has_some(minutes) do
    Enum.reduce(acc, [], fn recurrence, acc ->
      Enum.reduce(
        minutes,
        acc,
        fn minute, acc ->
          date =
            case recurrence do
              %Date{} = date -> DateTime.new!(date, Time.new!(0, minute, 0))
              %DateTime{} = date -> %{date | minute: minute}
            end

          [date | acc]
        end
      )
    end)
  end

  defp apply_modifier({:by_minute, :limit}, %{by_minute: minutes}, acc) when has_some(minutes) do
    Enum.filter(acc, fn recurrence ->
      case recurrence do
        %DateTime{minute: minute} -> Enum.member?(minutes, minute)
        _ -> false
      end
    end)
  end

  defp apply_modifier({:by_second, :expand}, %{by_second: seconds}, acc) when has_some(seconds) do
    Enum.reduce(acc, [], fn recurrence, acc ->
      Enum.reduce(
        seconds,
        acc,
        fn second, acc ->
          date =
            case recurrence do
              %Date{} = date -> DateTime.new!(date, Time.new!(0, 0, second))
              %DateTime{} = date -> %{date | second: second}
            end

          [date | acc]
        end
      )
    end)
  end

  defp apply_modifier({:by_second, :limit}, %{by_second: seconds}, acc) when has_some(seconds) do
    Enum.filter(acc, fn recurrence ->
      case recurrence do
        %DateTime{second: second} -> Enum.member?(seconds, second)
        _ -> false
      end
    end)
  end

  defp apply_modifier({:by_set_position, :limit}, %{by_set_position: positions}, recurrences)
       when has_some(positions) do
    Enum.reduce(positions, [], fn index, acc ->
      index = if index > 0, do: index - 1, else: index

      case Enum.at(recurrences, index) do
        nil -> acc
        recurrence -> [recurrence | acc]
      end
    end)
  end

  defp apply_modifier(_, _rule, acc), do: acc

  defp exclude(recurrences, %{earliest_date: earliest, exclude_dates: exclude_dates}) do
    in_set =
      if has_some(exclude_dates) do
        Enum.filter(recurrences, fn recurrence ->
          not in_dates?(exclude_dates, recurrence)
        end)
      else
        recurrences
      end

    index =
      Enum.find_index(in_set, fn recurrence ->
        is_not_before(recurrence, earliest)
      end)

    case index do
      nil -> []
      0 -> in_set
      index -> Enum.slice(in_set, index..-1//1)
    end
  end

  defp in_dates?(all_dates, recurrence) do
    Enum.reduce(all_dates, false, fn date, acc -> acc or equal?(date, recurrence) end)
  end

  defp include_all_other(recurrences, %{other_recurrences: []} = state) do
    {recurrences, state}
  end

  defp include_all_other(recurrences, %{other_recurrences: other_recurrences} = state) do
    {
      Enum.sort(recurrences ++ other_recurrences, &compare_recurrences/2),
      %{state | other_recurrences: []}
    }
  end

  defp include_other(recurrences, %{limit: :reached} = state) do
    {recurrences, remaining_other} = merge_other(recurrences, state.other_recurrences)
    include_all_other(recurrences, %{state | other_recurrences: remaining_other})
  end

  defp include_other(recurrences, %{other_recurrences: [_ | _] = other_recurrences} = state) do
    {recurrences, remaining_other} = merge_other(recurrences, other_recurrences)
    {recurrences, %{state | other_recurrences: remaining_other}}
  end

  defp include_other(recurrences, state) do
    {recurrences, state}
  end

  @spec merge_other(
          recurrences :: [ICal.Recurrence.recurrence_date()],
          other :: [ICal.Recurrence.recurrence_date()]
        ) ::
          {merged_recurrences :: [ICal.Recurrence.recurrence_date()],
           remaining_other :: [ICal.Recurrence.recurrence_date()]}
  defp merge_other(recurrences, []) do
    {recurrences, []}
  end

  defp merge_other(recurrences, other_recurrences) do
    Enum.reduce(recurrences, {[], other_recurrences}, fn
      recurrence, {acc, []} ->
        {acc ++ [recurrence], []}

      recurrence, {acc, other_recurrences} ->
        # other_recurrences is sorted, so only compare until a failure
        index =
          Enum.reduce_while(other_recurrences, -1, fn other_recurrence, index ->
            if is_after(recurrence, other_recurrence) do
              {:cont, index + 1}
            else
              {:halt, index}
            end
          end)

        if index > -1 do
          {inclusions, other_recurrences} = Enum.split(other_recurrences, index + 1)
          {acc ++ inclusions ++ [recurrence], other_recurrences}
        else
          {acc ++ [recurrence], other_recurrences}
        end
    end)
  end

  defp add_rule_limits(state, %{count: count}, end_date) when is_integer(count) do
    %{state | limit: count, end_date: end_date}
  end

  defp add_rule_limits(state, %{until: until}, end_date) do
    # when until is a date time, set the until into the same timezone as the start date
    # it can not just be shifted, as the literal values should remain as they are
    until =
      case until do
        %DateTime{} ->
          DateTime.new!(
            DateTime.to_date(until),
            DateTime.to_time(until),
            state.earliest_date.time_zone
          )

        _ ->
          until
      end

    if end_date != nil and is_after(until, end_date) do
      %{state | limit: end_date, end_date: end_date}
    else
      %{state | limit: until, end_date: end_date}
    end
  end

  defp beginning_of_week(%DateTime{} = date, start) do
    DateTime.new!(
      Date.beginning_of_week(DateTime.to_date(date), start),
      DateTime.to_time(date),
      date.time_zone
    )
  end

  defp beginning_of_week(%Date{} = date, start), do: Date.beginning_of_week(date, start)

  defp weekday_order do
    %{monday: 1, tuesday: 2, wednesday: 3, thursday: 4, friday: 5, saturday: 6, sunday: 7}
  end

  defp weekday(%Date{} = date) do
    index_date = Date.day_of_week(date)
    days = [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
    Enum.at(days, index_date - 1)
  end

  defp weekday(%DateTime{} = dt), do: weekday(DateTime.to_date(dt))

  defp generate_all_weekdays_in_month([last | _] = acc) do
    next = shift_date(last, week: 1)

    if next.month == last.month do
      generate_all_weekdays_in_month([next | acc])
    else
      acc
    end
  end

  # when no more recurrences are generated for too long, then stop even if it could in theory
  # go further.
  defp update_limit([], state) do
    {[], %{state | fruitless_searches: state.fruitless_searches + 1}}
  end

  defp update_limit(recurrences, %{limit: limit} = state) when is_integer(limit) do
    updated_limit = limit - Enum.count(recurrences)

    if updated_limit < 1 do
      recurrences
      |> Enum.slice(0, limit)
      |> include_other(%{state | limit: :reached})
    else
      new_state = %{
        state
        | limit: updated_limit,
          fruitless_searches: @fruitless_search_start_count
      }

      update_limit_by_date(recurrences, new_state.end_date, new_state)
    end
  end

  defp update_limit(recurrences, %{limit: limit_date} = state) do
    new_state = %{state | fruitless_searches: @fruitless_search_start_count}

    update_limit_by_date(recurrences, limit_date, new_state)
  end

  defp update_limit_by_date(recurrences, nil, state) do
    include_other(recurrences, state)
  end

  defp update_limit_by_date(recurrences, limit_date, state) do
    index =
      Enum.find_index(recurrences, fn recurrence -> is_after(recurrence, limit_date) end)

    if index != nil do
      recurrences
      |> Enum.slice(0, index)
      |> include_other(%{state | limit: :reached})
    else
      include_other(recurrences, state)
    end
  end

  def range(first, last, %Date{}) do
    Date.range(first, last) |> Enum.to_list()
  end

  def range(first, last, %DateTime{} = dt) do
    time = DateTime.to_time(dt)
    Date.range(first, last) |> Enum.map(fn date -> DateTime.new!(date, time, dt.time_zone) end)
  end

  defp shift_interval(date, {:date, interval}), do: shift_date(date, interval)

  defp shift_interval(date, {:time, interval}) do
    case date do
      %Date{} -> DateTime.new!(date, Time.new!(0, 0, 0), "Etc/UTC") |> DateTime.shift(interval)
      %DateTime{} -> DateTime.shift(date, interval)
    end
  end

  defp shift_date(%DateTime{} = date, interval) do
    shifted = DateTime.shift(date, interval)
    %{shifted | hour: date.hour, minute: date.minute, second: date.second}
  end

  defp shift_date(%Date{} = date, interval), do: Date.shift(date, interval)

  def week_number_bookends(date, week) do
    # shift the week
    if week > 0 do
      # positive week number, start from first w of the year
      end_date =
        Date.new!(date.year, 1, 1)
        |> Date.end_of_week()
        |> ensure_end_of_first_week()
        |> Date.shift(week: week - 1)

      start_date = Date.beginning_of_week(end_date)

      add_time_if_exists(date, start_date, end_date)
    else
      # negative week number, start from the last week of the year
      # and since it is already on the last week, move one less week than requested
      # e.g. the -1 week is 0 weeks from the last week of the year
      start_date =
        Date.new!(date.year + 1, 1, 1)
        |> Date.end_of_week()
        |> Date.shift(day: 1)
        |> Date.shift(week: week)

      end_date = start_date |> Date.end_of_week()

      add_time_if_exists(date, start_date, end_date)
    end
  end

  defp add_time_if_exists(%DateTime{} = date, start_date, end_date) do
    {
      DateTime.new!(start_date, DateTime.to_time(date), date.time_zone),
      DateTime.new!(end_date, DateTime.to_time(date), date.time_zone)
    }
  end

  defp add_time_if_exists(_, start_date, end_date), do: {start_date, end_date}

  defp days_in_month(%Date{} = date), do: Date.days_in_month(date)
  defp days_in_month(date), do: Date.days_in_month(DateTime.to_date(date))

  # the first week is considered the one with at least 4 days
  # so if the end of the first week is 3 or less, then bump it by a week
  defp ensure_end_of_first_week(%{day: day} = date) when day < 4, do: Date.shift(date, week: 1)
  defp ensure_end_of_first_week(day), do: day

  defp is_between_inclusive(earliest, middle, latest) do
    not is_after(earliest, middle) and not is_after(middle, latest)
  end

  defp equal?(%Date{} = d, %DateTime{} = dt), do: equal?(d, DateTime.to_date(dt))
  defp equal?(%DateTime{} = dt, %Date{} = d), do: equal?(DateTime.to_date(dt), d)
  defp equal?(l, r), do: l == r

  defp is_not_before(%Date{} = d, %DateTime{} = dt), do: is_not_before(d, DateTime.to_date(dt))
  defp is_not_before(%DateTime{} = dt, %Date{} = d), do: is_not_before(DateTime.to_date(dt), d)
  defp is_not_before(%Date{} = l, r), do: not Date.before?(l, r)
  defp is_not_before(%DateTime{} = l, r), do: not DateTime.before?(l, r)

  defp is_after(%Date{} = d, %DateTime{} = dt), do: is_after(d, DateTime.to_date(dt))
  defp is_after(%DateTime{} = dt, %Date{} = d), do: is_after(DateTime.to_date(dt), d)
  defp is_after(%Date{} = l, r), do: Date.after?(l, r)
  defp is_after(%DateTime{} = l, r), do: DateTime.after?(l, r)
end
