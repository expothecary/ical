defmodule ICal.Recurrence.Generate do
  @moduledoc false

  require Logger
  alias ICal.Recurrence.State

  @fruitless_search_start_count 0
  @max_fruitless_search_depth 1000

  defguard has_some(x) when is_list(x) and x != []
  defguard has_none(x) when not has_some(x)

  @type recurrence :: Date.t() | DateTime.t() | NaiveDateTime.t()
  @type error_reasons :: :search_exhaustion | :no_defined_limit

  @spec init(ICal.Recurrence.t(), start_date :: recurrence, end_date :: nil | recurrence) ::
          State.t()
  def init(rule, start_date, end_date \\ nil, exclude_dates \\ []) do
    %State{
      start_date: start_date,
      interval: rule_interval(rule),
      modifiers: rule_modifiers(rule),
      rule: rule,
      exclude_dates: exclude_dates
    }
    |> add_rule_limits(rule, end_date)
  end

  @spec all(ICal.Recurrence.t(), starting_from :: recurrence) ::
          {:ok, [recurrence]} | {:error, error_reasons, [recurrence]}
  def all(rule, start_date) do
    init(rule, start_date)
    |> generate_all()
  end

  @spec one_set(State.t()) :: {[recurrence], State.t()}
  def one_set(%State{} = state) do
    generate_set(state)
  end

  defp rule_interval(%ICal.Recurrence{frequency: :yearly, interval: interval}) do
    [year: interval]
  end

  defp rule_interval(%ICal.Recurrence{frequency: :monthly, interval: interval}) do
    [month: interval]
  end

  defp rule_interval(%ICal.Recurrence{frequency: :weekly, interval: interval}) do
    [week: interval]
  end

  defp rule_interval(%ICal.Recurrence{frequency: :daily, interval: interval}) do
    [day: interval]
  end

  defp rule_interval(%ICal.Recurrence{frequency: :hourly, interval: interval}) do
    [hour: interval]
  end

  defp rule_interval(%ICal.Recurrence{frequency: :minutely, interval: interval}) do
    [minute: interval]
  end

  defp rule_interval(%ICal.Recurrence{frequency: :secondly, interval: interval}) do
    [second: interval]
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
        has_some(rule.by_week_number) -> :expand_week
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

  defp generate_all(%{limit: limit}, acc)
       when is_integer(limit) and limit < 1, do: {:ok, acc}

  defp generate_all(%{fruitless_searches: fruitless_searches, rule: rule}, acc)
       when fruitless_searches > @max_fruitless_search_depth do
    Logger.warning("Could not find all recurrences of #{inspect(rule)} due to search exhaustion")
    {:error, :search_exhaustion, acc}
  end

  defp generate_all(state, acc) do
    {recurrences, new_state} = generate_set(state)

    if new_state.limit == :reached do
      {:ok, acc ++ recurrences}
    else
      generate_all(new_state, acc ++ recurrences)
    end
  end

  defp generate_set(%State{} = state) do
    recurrences =
      [state.start_date]
      |> apply_all_modifiers(state)
      |> exclude(state)

    new_state = %{state | start_date: shift(state.start_date, state.interval)}
    update_limit(recurrences, new_state)
  end

  defp apply_all_modifiers(recurrences, %{modifiers: modifiers, rule: rule}) do
    Enum.reduce(modifiers, recurrences, fn modifier, acc ->
      apply_modifier(modifier, rule, acc)
      |> Enum.reduce([], &only_valid_dates/2)
      |> Enum.sort(&compare_recurrences/2)
    end)
  end

  defp only_valid_dates(%NaiveDateTime{} = date, acc) do
    case NaiveDateTime.new(NaiveDateTime.to_date(date), NaiveDateTime.to_time(date)) do
      {:ok, date} -> acc ++ [date]
      _ -> acc
    end
  end

  defp only_valid_dates(%Date{} = date, acc) do
    case Date.new(date.year, date.month, date.day) do
      {:ok, date} -> acc ++ [date]
      _ -> acc
    end
  end

  defp only_valid_dates(%DateTime{} = datetime, acc) do
    case ICal.as_valid_datetime(
           DateTime.to_date(datetime),
           DateTime.to_time(datetime),
           datetime.time_zone
         ) do
      nil -> acc
      datetime -> acc ++ [datetime]
    end
  end

  defp compare_recurrences(%DateTime{} = l, r), do: DateTime.compare(l, r) == :lt
  defp compare_recurrences(%NaiveDateTime{} = l, r), do: NaiveDateTime.compare(l, r) == :lt
  defp compare_recurrences(%Date{} = l, r), do: Date.compare(l, r) == :lt

  defp apply_modifier({:by_month, :expand}, %{by_month: months}, acc) when has_some(months) do
    Enum.reduce(acc, [], fn recurrence, acc ->
      acc ++
        Enum.map(months, fn month ->
          if month > recurrence.month do
            %{recurrence | month: month}
          else
            %{recurrence | year: recurrence.year + 1, month: month}
          end
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
      recurrence_week = week_of_year(recurrence)

      acc ++
        Enum.flat_map(weeks, fn week ->
          reference_date =
            if week > recurrence_week do
              recurrence
            else
              %{recurrence | year: recurrence.year + 1}
            end

          {first, last} =
            week_number_bookends(reference_date, week)

          range(first, last, recurrence)
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
    |> Enum.flat_map(fn recurrence ->
      orig_day_of_year = day_of_year(recurrence)
      first_of_jan = %{recurrence | month: 1, day: 1}

      Enum.map(year_days, fn day_of_year ->
        if day_of_year > orig_day_of_year do
          shift(first_of_jan, day: day_of_year - 1)
        else
          shift(first_of_jan, year: 1, day: day_of_year - 1)
        end
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
    acc
    |> Enum.flat_map(fn recurrence ->
      Enum.map(month_days, fn month_day ->
        %{recurrence | day: month_day}
      end)
    end)
  end

  defp apply_modifier({:by_month_day, :limit}, %{by_month_day: month_days}, acc)
       when has_some(month_days) do
    Enum.filter(acc, fn recurrence ->
      Enum.member?(month_days, recurrence.day)
    end)
  end

  # TODO
  defp apply_modifier({:by_day, :expand_year}, %{by_day: days}, acc) when has_some(days) do
    acc
  end

  defp apply_modifier({:by_day, :expand_month}, %{by_day: days}, acc) when has_some(days) do
    acc
  end

  defp apply_modifier({:by_day, :expand_week}, %{by_day: days}, acc) when has_some(days) do
    acc
  end

  defp apply_modifier({:by_day, :limit}, %{by_day: days}, acc) when has_some(days) do
    Enum.filter(acc, fn recurrence ->
      target = weekday(recurrence)
      Enum.find(days, fn {_, allowed_day} -> allowed_day == target end) != nil
    end)
  end

  # TODO
  defp apply_modifier({:by_hour, :expand}, %{by_hour: hours}, acc) when has_some(hours) do
    acc
  end

  # TODO
  defp apply_modifier({:by_hour, :limit}, %{by_hour: hours}, acc) when has_some(hours) do
    acc
  end

  # TODO
  defp apply_modifier({:by_minute, :expand}, %{by_minute: minutes}, acc) when has_some(minutes) do
    acc
  end

  # TODO
  defp apply_modifier({:by_minute, :limit}, %{by_minute: minutes}, acc) when has_some(minutes) do
    acc
  end

  # TODO
  defp apply_modifier({:by_second, :expand}, %{by_second: seconds}, acc) when has_some(seconds) do
    acc
  end

  # TODO
  defp apply_modifier({:by_second, :limit}, %{by_second: seconds}, acc) when has_some(seconds) do
    acc
  end

  defp apply_modifier({:by_set_position, :limit}, %{by_set_position: index}, recurrences)
       when is_integer(index) and index != 0 do
    index = if index > 0, do: index - 1, else: index

    case Enum.at(recurrences, index) do
      nil -> []
      recurrence -> [recurrence]
    end

    recurrences
  end

  defp apply_modifier(_, _rule, acc), do: acc

  defp exclude(recurrences, %{start_date: start_date, exclude_dates: exclude_dates}) do
    Enum.filter(recurrences, fn recurrence ->
      is_not_before(recurrence, start_date) and not in_dates?(exclude_dates, recurrence)
    end)
  end

  defp in_dates?(all_dates, recurrence) do
    Enum.reduce(all_dates, false, fn date, acc -> acc or equal?(date, recurrence) end)
  end

  defp add_rule_limits(state, %{count: count}, end_date) when is_integer(count) do
    %{state | limit: count, end_date: end_date}
  end

  defp add_rule_limits(state, %{until: until}, end_date) do
    if end_date != nil and is_after(until, end_date) do
      %{state | limit: end_date, end_date: end_date}
    else
      %{state | limit: until, end_date: end_date}
    end
  end

  # TODO: is the start of the week needed here?
  def weekday(%Date{} = date) do
    index_date = Date.day_of_week(date)
    days = [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
    Enum.at(days, index_date - 1)
  end

  def weekday(%DateTime{} = dt), do: weekday(DateTime.to_date(dt))

  # when no more recurrences are generated for too long, then stop even if it could in theory
  # go further.
  defp update_limit([], state) do
    {[], %{state | fruitless_searches: state.fruitless_searches + 1}}
  end

  defp update_limit(recurrences, %{limit: limit} = state) when is_integer(limit) do
    updated_limit = limit - Enum.count(recurrences)

    if updated_limit < 1 do
      {Enum.slice(recurrences, 0, limit), %{state | limit: :reached}}
    else
      new_state = %{
        state
        | limit: updated_limit,
          fruitless_searches: @fruitless_search_start_count
      }

      update_limit_by_date(recurrences, state.end_date, new_state)
    end
  end

  defp update_limit(recurrences, %{limit: limit_date} = state) do
    new_state = %{state | fruitless_searches: @fruitless_search_start_count}

    update_limit_by_date(recurrences, limit_date, new_state)
  end

  defp update_limit_by_date(recurrences, nil, state) do
    {recurrences, state}
  end

  defp update_limit_by_date(recurrences, limit_date, state) do
    index = Enum.find_index(recurrences, fn recurrence -> is_after(recurrence, limit_date) end)

    if index != nil do
      {Enum.slice(recurrences, 0, index), %{state | limit: :reached}}
    else
      {recurrences, state}
    end
  end

  def range(first, last, %Date{}) do
    Date.range(first, last) |> Enum.to_list()
  end

  def range(first, last, %DateTime{} = dt) do
    time = DateTime.to_time(dt)
    Date.range(first, last) |> Enum.map(fn date -> DateTime.new!(date, time) end)
  end

  defp shift(%DateTime{} = start_date, interval), do: DateTime.shift(start_date, interval)
  defp shift(%Date{} = start_date, interval), do: Date.shift(start_date, interval)

  def week_number_bookends(start_date, week) do
    # shift the week
    if week > 0 do
      # positive week number, start from first w of the year
      end_date =
        Date.new!(start_date.year, 1, 1)
        |> Date.end_of_week()
        |> ensure_end_of_first_week()
        |> Date.shift(week: week - 1)

      start_date = Date.beginning_of_week(end_date)

      {start_date, end_date}
    else
      # negative week number, start from the last week of the year
      # and since it is already on the last week, move one less week than requested
      # e.g. the -1 week is 0 weeks from the last week of the year
      start_date =
        Date.new!(start_date.year + 1, 1, 1)
        |> Date.end_of_week()
        |> Date.shift(day: 1)
        |> Date.shift(week: week)

      end_date = start_date |> Date.end_of_week()

      {start_date, end_date}
    end
  end

  defp week_of_year(%DateTime{} = datetime), do: week_of_year(DateTime.to_date(datetime))

  defp week_of_year(%NaiveDateTime{} = datetime),
    do: week_of_year(NaiveDateTime.to_date(datetime))

  defp week_of_year(%Date{} = date) do
    end_of_first_week =
      Date.new!(date.year, 1, 1)
      |> Date.end_of_week()
      |> ensure_end_of_first_week()
      |> Date.day_of_year()

    end_of_this_week =
      date
      |> Date.end_of_week()
      |> Date.day_of_year()

    week =
      (end_of_this_week - end_of_first_week)
      |> Integer.floor_div(7)

    week + 1
  end

  # the first week is considered the one with at least 4 days
  # so if the end of the first week is 3 or less, then bump it by a week
  defp ensure_end_of_first_week(%{day: day} = date) when day < 4, do: Date.shift(date, week: 1)
  defp ensure_end_of_first_week(day), do: day

  defp day_of_year(%DateTime{} = datetime), do: day_of_year(DateTime.to_date(datetime))
  defp day_of_year(%NaiveDateTime{} = datetime), do: day_of_year(NaiveDateTime.to_date(datetime))
  defp day_of_year(%Date{} = date), do: Date.day_of_year(date)

  defp is_between_inclusive(earliest, middle, latest) do
    is_not_after(earliest, middle) and is_not_after(middle, latest)
  end

  defp equal?(%Date{} = d, %DateTime{} = dt), do: equal?(d, DateTime.to_date(dt))

  defp equal?(%DateTime{} = dt, %Date{} = d),
    do: equal?(dt, DateTime.new!(d, Time.new(0, 0, 0), dt.time_zone))

  defp equal?(l, r), do: l == r

  defp is_not_before(%Date{} = d, %DateTime{} = dt), do: is_not_before(d, DateTime.to_date(dt))
  defp is_not_before(%DateTime{} = dt, %Date{} = d), do: is_not_before(DateTime.to_date(dt), d)
  defp is_not_before(%Date{} = l, r), do: Date.compare(l, r) != :lt
  defp is_not_before(%DateTime{} = l, r), do: DateTime.compare(l, r) != :lt

  defp is_after(%Date{} = d, %DateTime{} = dt), do: is_after(d, DateTime.to_date(dt))
  defp is_after(%DateTime{} = dt, %Date{} = d), do: is_after(DateTime.to_date(dt), d)
  defp is_after(%Date{} = l, r), do: Date.compare(l, r) == :gt
  defp is_after(%DateTime{} = l, r), do: DateTime.compare(l, r) == :gt

  defp is_not_after(%Date{} = d, %DateTime{} = dt), do: is_not_after(d, DateTime.to_date(dt))
  defp is_not_after(%DateTime{} = dt, %Date{} = d), do: is_not_after(DateTime.to_date(dt), d)
  defp is_not_after(%Date{} = l, r), do: Date.compare(l, r) != :gt
  defp is_not_after(%DateTime{} = l, r), do: DateTime.compare(l, r) != :gt
end
