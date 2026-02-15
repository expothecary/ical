defmodule ICal.Deserialize.Recurrence do
  @moduledoc false

  alias ICal.Deserialize

  @spec from_params(map) :: ICal.Recurrence.t() | nil

  def from_params(%{} = params) do
    add_frequency(%ICal.Recurrence{}, params)
  end

  @spec from_event(map | ICal.Event.t()) :: ICal.Recurrence.t() | nil
  def from_event(%ICal.Event{rrule: %ICal.Recurrence{} = rule}), do: rule
  def from_event(%ICal.Event{rrule: nil}), do: nil

  def from_event(%ICal.Event{} = event) do
    add_frequency(%ICal.Recurrence{}, event.rrule)
  end

  defp add_frequency(recurrence, params) do
    with freq when not is_nil(freq) <- Map.get(params, "FREQ"),
         {:ok, frequency} <- to_frequency_atom(freq) do
      Enum.reduce(
        params,
        %{recurrence | frequency: frequency},
        &add_to_recurrence/2
      )
    else
      _ -> nil
    end
  end

  defp add_to_recurrence({"UNTIL", value}, recurrence) do
    date = Deserialize.to_date_in_timezone(value, "Etc/UTC")
    %{recurrence | until: date}
  end

  defp add_to_recurrence({<<"BY", unit::binary>>, value}, recurrence) do
    add_by_list_to_recurrence(unit, value, recurrence)
  end

  defp add_to_recurrence({"COUNT", value}, recurrence) do
    add_integer_value(recurrence, :count, value)
  end

  defp add_to_recurrence({"INTERVAL", value}, recurrence) do
    add_integer_value(recurrence, :interval, value)
  end

  defp add_to_recurrence({"WKST", value}, recurrence) do
    case to_week_day(value) do
      :error -> recurrence
      {weekday_atom, _} -> %{recurrence | weekday: weekday_atom}
    end
  end

  defp add_to_recurrence(_, recurrence), do: recurrence

  defp add_by_list_to_recurrence("SECOND", value, recurrence) do
    number_list = to_clamped_numbers(value, 0, 59)
    %{recurrence | by_second: number_list}
  end

  defp add_by_list_to_recurrence("MINUTE", value, recurrence) do
    number_list = to_clamped_numbers(value, 0, 59)
    %{recurrence | by_minute: number_list}
  end

  defp add_by_list_to_recurrence("HOUR", value, recurrence) do
    number_list = to_clamped_numbers(value, 0, 23)
    %{recurrence | by_hour: number_list}
  end

  defp add_by_list_to_recurrence("DAY", value, recurrence) do
    number_list = to_week_days(value)
    %{recurrence | by_day: number_list}
  end

  defp add_by_list_to_recurrence("MONTH", value, recurrence) do
    number_list = to_clamped_numbers(value, 1, 12)
    %{recurrence | by_month: number_list}
  end

  defp add_by_list_to_recurrence("MONTHDAY", value, recurrence) do
    number_list = to_clamped_numbers(value, -31, 31)
    %{recurrence | by_month_day: number_list}
  end

  defp add_by_list_to_recurrence("YEARDAY", value, recurrence) do
    number_list = to_clamped_numbers(value, -366, 366)
    %{recurrence | by_year_day: number_list}
  end

  defp add_by_list_to_recurrence("WEEKNO", value, recurrence) do
    number_list = to_clamped_numbers(value, -53, 53)
    %{recurrence | by_week_number: number_list}
  end

  defp add_by_list_to_recurrence("SETPOS", value, recurrence) do
    number_list = to_clamped_numbers(value, -366, 366)
    %{recurrence | by_set_position: number_list}
  end

  defp add_integer_value(recurrence, key, value) do
    case Integer.parse(value) do
      {number, ""} -> Map.put(recurrence, key, number)
      _ -> recurrence
    end
  end

  defp to_clamped_numbers(string, min, max) do
    to_clamped_numbers(string, min, max, min >= 0, "", [])
  end

  defp to_clamped_numbers(<<>>, min, max, zeros?, value, acc) do
    case Integer.parse(value) do
      {number, ""} when number >= min and number <= max and (zeros? or number != 0) ->
        acc ++ [number]

      _ ->
        acc
    end
  end

  defp to_clamped_numbers(<<?,, string::binary>>, min, max, zeros?, value, acc) do
    acc =
      case Integer.parse(value) do
        {number, ""} when number >= min and number <= max and (zeros? or number != 0) ->
          acc ++ [number]

        _ ->
          acc
      end

    to_clamped_numbers(string, min, max, zeros?, "", acc)
  end

  defp to_clamped_numbers(<<c, string::binary>>, min, max, zeros?, value, acc) do
    to_clamped_numbers(string, min, max, zeros?, <<value::binary, c>>, acc)
  end

  defp to_week_days(string), do: to_week_days(string, [])
  defp to_week_days(<<>>, acc), do: acc
  defp to_week_days(<<?,, string::binary>>, acc), do: to_week_days(string, acc)
  defp to_week_days(<<?+, string::binary>>, acc), do: to_offset_week_days(string, <<>>, acc)
  defp to_week_days(<<?-, string::binary>>, acc), do: to_offset_week_days(string, <<?->>, acc)

  defp to_week_days(<<n, string::binary>>, acc) when n >= ?0 and n <= ?9 do
    to_offset_week_days(string, <<n>>, acc)
  end

  defp to_week_days(string, acc) do
    to_week_day_with_offset(string, 0, acc)
  end

  defp skip_to_comma(<<>>), do: <<>>
  defp skip_to_comma(<<?,, string::binary>>), do: string
  defp skip_to_comma(<<_::utf8, string::binary>>), do: skip_to_comma(string)

  defp to_offset_week_days(<<n::utf8, string::binary>>, offset, acc) when n >= ?0 and n <= ?9 do
    to_offset_week_days(string, <<offset::binary, n::utf8>>, acc)
  end

  defp to_offset_week_days(string, offset, acc) do
    offset =
      case Integer.parse(offset) do
        {number, ""} -> number
        _ -> 0
      end

    to_week_day_with_offset(string, offset, acc)
  end

  defp to_week_day_with_offset(string, offset, acc) do
    case to_week_day(string) do
      {weekday, string} -> to_week_days(string, acc ++ [{offset, weekday}])
      :error -> to_week_days(skip_to_comma(string), acc)
    end
  end

  defp to_week_day(<<"SU", rest::binary>>), do: {:sunday, rest}
  defp to_week_day(<<"MO", rest::binary>>), do: {:monday, rest}
  defp to_week_day(<<"TU", rest::binary>>), do: {:tuesday, rest}
  defp to_week_day(<<"WE", rest::binary>>), do: {:wednesday, rest}
  defp to_week_day(<<"TH", rest::binary>>), do: {:thursday, rest}
  defp to_week_day(<<"FR", rest::binary>>), do: {:friday, rest}
  defp to_week_day(<<"SA", rest::binary>>), do: {:saturday, rest}
  defp to_week_day(_), do: :error

  @spec to_frequency_atom(String.t()) :: {:ok, ICal.Recurrence.frequency()} | :error
  defp to_frequency_atom("DAILY"), do: {:ok, :daily}
  defp to_frequency_atom("WEEKLY"), do: {:ok, :weekly}
  defp to_frequency_atom("MONTHLY"), do: {:ok, :monthly}
  defp to_frequency_atom("YEARLY"), do: {:ok, :yearly}
  defp to_frequency_atom("HOURLY"), do: {:ok, :hourly}
  defp to_frequency_atom("MINUTELY"), do: {:ok, :minutely}
  defp to_frequency_atom("SECONDLY"), do: {:ok, :secondly}
  defp to_frequency_atom(_), do: :error
end
