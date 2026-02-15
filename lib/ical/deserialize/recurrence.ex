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
      weekday_atom -> %{recurrence | weekday: weekday_atom}
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

  # TODO: parse +/-#
  defp to_week_days(string), do: to_week_days(string, [])
  defp to_week_days(<<>>, acc), do: acc
  defp to_week_days(<<?,, string::binary>>, acc), do: to_week_days(string, acc)
  defp to_week_days(<<"SU", string::binary>>, acc), do: to_week_days(string, [:sunday | acc])
  defp to_week_days(<<"MO", string::binary>>, acc), do: to_week_days(string, [:monday | acc])
  defp to_week_days(<<"TU", string::binary>>, acc), do: to_week_days(string, [:tuesday | acc])
  defp to_week_days(<<"WE", string::binary>>, acc), do: to_week_days(string, [:wednesday | acc])
  defp to_week_days(<<"TH", string::binary>>, acc), do: to_week_days(string, [:thursday | acc])
  defp to_week_days(<<"FR", string::binary>>, acc), do: to_week_days(string, [:friday | acc])
  defp to_week_days(<<"SA", string::binary>>, acc), do: to_week_days(string, [:saturday | acc])
  defp to_week_days(<<_, string::binary>>, acc), do: to_week_days(string, acc)

  defp to_week_day("SU"), do: :sunday
  defp to_week_day("MO"), do: :monday
  defp to_week_day("TU"), do: :tuesday
  defp to_week_day("WE"), do: :wednesday
  defp to_week_day("TH"), do: :thursday
  defp to_week_day("FR"), do: :friday
  defp to_week_day("SA"), do: :saturday
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
