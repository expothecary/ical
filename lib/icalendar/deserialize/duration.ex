defmodule ICalendar.Deserialize.Duration do
  @moduledoc false

  def from_ics(<<"P", data::binary>>) do
    parse(data, %ICalendar.Duration{positive: true})
  end

  def from_ics(<<"+P", data::binary>>) do
    parse(data, %ICalendar.Duration{positive: true})
  end

  def from_ics(<<"-P", data::binary>>) do
    parse(data, %ICalendar.Duration{positive: false})
  end

  def from_ics(data) do
    {data, nil}
  end

  defp parse(<<>> = data, duration) do
    {data, duration}
  end

  defp parse(<<?\n, _::binary>> = data, duration) do
    {data, duration}
  end

  defp parse(<<digit, data::binary>>, duration) when digit >= ?0 and digit <= ?9 do
    parse_numeric_part(data, <<digit>>, duration)
  end

  defp parse(<<"T", data::binary>>, duration) do
    {data, time} = parse_time_amount(data, {0, 0, 0})
    parse(data, %{duration | time: time})
  end

  defp parse_numeric_part(<<digit, data::binary>>, acc, duration)
       when digit >= ?0 and digit <= ?9 do
    parse_numeric_part(data, <<acc::binary, digit>>, duration)
  end

  defp parse_numeric_part(<<?W, data::binary>>, acc, duration) do
    weeks = String.to_integer(acc)
    parse(data, %{duration | weeks: weeks})
  end

  defp parse_numeric_part(<<?D, data::binary>>, acc, duration) do
    days = String.to_integer(acc)
    parse(data, %{duration | days: days})
  end

  defp parse_time_amount(data, time), do: parse_time_amount(data, <<>>, time)

  defp parse_time_amount(<<digit, data::binary>>, acc, time)
       when digit >= ?0 and digit <= ?9 do
    parse_time_amount(data, <<acc::binary, digit>>, time)
  end

  defp parse_time_amount(<<?H, data::binary>>, acc, {_hours, minutes, seconds}) do
    hours = String.to_integer(acc)
    parse_time_amount(data, {hours, minutes, seconds})
  end

  defp parse_time_amount(<<?M, data::binary>>, acc, {hours, _minutes, seconds}) do
    minutes = String.to_integer(acc)
    parse_time_amount(data, {hours, minutes, seconds})
  end

  defp parse_time_amount(<<?S, data::binary>>, acc, {hours, minutes, _seconds}) do
    seconds = String.to_integer(acc)
    parse_time_amount(data, {hours, minutes, seconds})
  end

  # put the accumulated string back on the buffer in case it pulled off some numbers
  defp parse_time_amount(data, acc, time), do: {acc <> data, time}
end
