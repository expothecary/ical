defmodule ICal.Recurrence.Generate do
  @moduledoc false

  defguard has_some(x) when is_list(x) and x != []
  defguard has_none(x) when not has_some(x)

  def all(%ICal.Recurrence{frequency: :yearly, interval: interval} = rule, dtstart) do
    generate(
      limiter(rule),
      dtstart,
      [year: interval],
      [
        :by_month,
        :by_week_number,
        :by_year_day,
        :by_month_day,
        :by_day,
        :by_hour,
        :by_minute,
        :by_second
      ],
      [:by_set_position],
      rule
    )
  end

  def all(%ICal.Recurrence{frequency: :monthly, interval: interval} = rule, dtstart) do
    generate(
      limiter(rule),
      dtstart,
      [month: interval],
      [:by_month_day, :by_day, :by_hour, :by_minute, :by_second],
      [:by_month, :by_set_position],
      rule
    )
  end

  def all(%ICal.Recurrence{frequency: :weekly, interval: interval} = rule, dtstart) do
    generate(
      limiter(rule),
      dtstart,
      [week: interval],
      [:by_day, :by_hour, :by_minute, :by_second],
      [:by_month, :by_set_position],
      rule
    )
  end

  def all(%ICal.Recurrence{frequency: :daily, interval: interval} = rule, dtstart) do
    generate(
      limiter(rule),
      dtstart,
      [day: interval],
      [:by_hour, :by_minute, :by_second],
      [:by_month, :by_day, :by_set_position],
      rule
    )
  end

  def all(%ICal.Recurrence{frequency: :hourly, interval: interval} = rule, dtstart) do
    generate(
      limiter(rule),
      dtstart,
      [hour: interval],
      [:by_minute, :by_second],
      [:by_month, :by_year_day, :by_month_day, :by_day, :by_hour, :by_set_position],
      rule
    )
  end

  def all(%ICal.Recurrence{frequency: :minutely, interval: interval} = rule, dtstart) do
    generate(
      limiter(rule),
      dtstart,
      [minute: interval],
      [:by_second],
      [:by_month, :by_year_day, :by_month_day, :by_day, :by_hour, :by_minute, :by_set_position],
      rule
    )
  end

  def all(%ICal.Recurrence{frequency: :secondly, interval: interval} = rule, dtstart) do
    generate(
      limiter(rule),
      dtstart,
      [second: interval],
      [],
      [
        :by_month,
        :by_year_day,
        :by_month_day,
        :by_day,
        :by_hour,
        :by_minute,
        :by_second,
        :by_set_position
      ],
      rule
    )
  end

  defp generate(limit, dtstart, offset, expanders, limiters, rule) do
    recurrences =
      [dtstart]
      |> expand(expanders, rule)
      |> limit(limiters, rule)
      |> Enum.filter(fn date -> is_not_before(date, dtstart) end)

    {limit, recurrences} = update_limit(limit, recurrences)

    generate(
      limit,
      dtstart,
      offset,
      expanders,
      limiters,
      rule,
      recurrences
    )
  end

  defp generate(limit, _dtstart, _offset, _expanders, _limiters, _rule, acc)
       when is_integer(limit) and limit < 1, do: acc

  defp generate(limit, dtstart, offset, expanders, limiters, rule, acc) do
    dtnext = shift(dtstart, offset)

    recurrences =
      [dtnext]
      |> expand(expanders, rule)
      |> limit(limiters, rule)

    {limit, recurrences} = update_limit(limit, recurrences)

    if limit == nil do
      acc ++ recurrences
    else
      generate(
        limit,
        dtnext,
        offset,
        expanders,
        limiters,
        rule,
        acc ++ recurrences
      )
    end
  end

  defp expand(recurrences, expanders, rule) do
    Enum.reduce(expanders, recurrences, fn expand_by, acc -> expand_by(expand_by, rule, acc) end)
  end

  defp limit(recurrences, limiters, rule) do
    Enum.reduce(limiters, recurrences, fn limit_by, acc -> limit_by(limit_by, rule, acc) end)
  end

  defp expand_by(:by_month, %{by_month: months}, acc) when has_some(months) do
    Enum.reduce(acc, [], fn dtstart, acc ->
      acc ++ Enum.map(months, fn month -> %{dtstart | month: month} end)
    end)
  end

  defp expand_by(:by_week_number, %{by_week_number: weeks}, acc) when has_none(weeks), do: acc

  defp expand_by(:by_week_number, %{by_month: months} = rule, acc) when has_some(months) do
    # it was expanded by months, so limit the occurances by week number
    limit_by(:by_week_number, rule, acc)
  end

  defp expand_by(:by_week_number, %{by_week_number: weeks}, acc) do
    Enum.reduce(acc, [], fn recurrence, acc ->
      acc ++
        Enum.flat_map(weeks, fn week ->
          {first, last} =
            week_number_bookends(recurrence, week)

          range(first, last, recurrence)
        end)
    end)
  end

  defp expand_by(:by_year_day, %{by_year_day: days}, acc) when has_none(days) do
    acc
  end

  defp expand_by(:by_year_day, %{by_month: months, by_week_number: weeks} = rule, acc)
       when has_some(months) or has_some(weeks) do
    # we are limiting rather than expanding
    limit_by(:by_year_day, rule, acc)
  end

  defp expand_by(:by_year_day, %{by_year_day: year_days}, acc) do
    Enum.uniq_by(acc, fn recurrence -> recurrence.year end)
    |> Enum.flat_map(fn recurrence ->
      first_of_jan = %{recurrence | month: 1, day: 1}

      Enum.map(year_days, fn day_of_year ->
        shift(first_of_jan, day: day_of_year)
      end)
    end)
  end

  defp expand_by(_by, _rule, acc), do: acc

  defp limit_by(:by_set_position, %{by_set_position: index}, recurrences)
       when is_integer(index) and index != 0 do
    index = if index > 0, do: index - 1, else: index

    case Enum.at(recurrences, index) do
      nil -> []
      recurrence -> [recurrence]
    end
  end

  defp limit_by(:by_year_day, %{by_year_day: year_days}, acc) when has_some(year_days) do
    Enum.filter(acc, fn recurrence ->
      Enum.member?(year_days, Date.day_of_year(recurrence))
    end)
  end

  defp limit_by(:by_week_number, %{by_week_number: weeks}, acc) when has_some(weeks) do
    Enum.filter(acc, fn recurrence ->
      Enum.find(weeks, fn week ->
        {week_start, week_end} = week_number_bookends(recurrence, week)
        is_between(week_start, recurrence, week_end)
      end) != nil
    end)
  end

  defp limit_by(:by_month, %{by_month: months}, acc) when has_some(months) do
    Enum.filter(acc, fn recurrence ->
      Enum.member?(months, recurrence.month)
    end)
  end

  defp limit_by(:by_month_day, %{by_month_day: days}, acc) when has_some(days) do
    Enum.filter(acc, fn recurrence ->
      Enum.member?(days, recurrence.day)
    end)
  end

  defp limit_by(:by_day, %{by_day: days}, acc) when has_some(days) do
    Enum.filter(acc, fn recurrence ->
      target = weekday(recurrence)
      Enum.find(days, fn {_, allowed_day} -> allowed_day == target end) != nil
    end)
  end

  defp limit_by(_limiter, _rule, recurrences), do: recurrences

  defp limiter(%{count: count}) when is_integer(count), do: count
  defp limiter(%{until: until}), do: until

  # TODO: is the start of the week needed here?
  def weekday(%Date{} = date) do
    index_date = Date.day_of_week(date)
    days = [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday]
    Enum.at(days, index_date - 1)
  end

  def weekday(%DateTime{} = dt), do: weekday(DateTime.to_date(dt))

  defp update_limit(limit, recurrences) when is_integer(limit) do
    updated_limit = limit - Enum.count(recurrences)

    if updated_limit < 1 do
      {nil, Enum.slice(recurrences, 0, limit)}
    else
      {updated_limit, recurrences}
    end
  end

  defp update_limit(limit, recurrences) do
    index = Enum.find_index(recurrences, fn recurrence -> is_not_after(limit, recurrence) end)

    if index != nil do
      {nil, Enum.slice(recurrences, 0, index + 1)}
    else
      {limit, recurrences}
    end
  end

  def range(first, last, %Date{}) do
    Date.range(first, last) |> Enum.to_list()
  end

  def range(first, last, %DateTime{} = dt) do
    time = DateTime.to_time(dt)
    Date.range(first, last) |> Enum.map(fn date -> DateTime.new!(date, time) end)
  end

  defp shift(%DateTime{} = dtstart, offset), do: DateTime.shift(dtstart, offset)
  defp shift(%Date{} = dtstart, offset), do: Date.shift(dtstart, offset)

  def week_number_bookends(dtstart, week) do
    # shift the week
    if week > 0 do
      # positive week number, start from first day of the year
      start_date =
        Date.new!(dtstart.year, 1, 1)
        |> Date.shift(week: week - 1)
        |> Date.beginning_of_week()

      end_date =
        start_date
        |> Date.end_of_week()

      {start_date, end_date}
    else
      # negative week number, start from the last week of the year
      # and since it is already on the last week, move one less week than requested
      # e.g. the -1 week is 0 weeks from the last week of the year
      start_date =
        Date.new!(dtstart.year, 1, 1)
        |> Date.shift(year: 1)
        |> Date.end_of_week()
        |> Date.shift(day: 1)
        |> IO.inspect()
        |> Date.shift(week: week)

      end_date = start_date |> Date.end_of_week()

      {start_date, end_date}
    end
  end

  defp is_between(earliest, middle, latest) do
    is_not_after(earliest, middle) and is_not_after(middle, latest)
  end

  defp is_not_before(%Date{} = d, %DateTime{} = dt), do: is_not_before(d, DateTime.to_date(dt))
  defp is_not_before(%DateTime{} = dt, %Date{} = d), do: is_not_before(DateTime.to_date(dt), d)
  defp is_not_before(%Date{} = l, r), do: Date.compare(l, r) != :lt
  defp is_not_before(%DateTime{} = l, r), do: DateTime.compare(l, r) != :lt

  defp is_not_after(%Date{} = d, %DateTime{} = dt), do: is_not_after(d, DateTime.to_date(dt))
  defp is_not_after(%DateTime{} = dt, %Date{} = d), do: is_not_after(DateTime.to_date(dt), d)
  defp is_not_after(%Date{} = l, r), do: Date.compare(l, r) != :gt
  defp is_not_after(%DateTime{} = l, r), do: DateTime.compare(l, r) != :gt
end
