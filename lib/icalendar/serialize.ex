defmodule ICalendar.Serialize do
  @moduledoc false
  use Timex

  # Escapes backslashes, commas, semicolons and newlines
  def to_ics(x) when is_binary(x) do
    x
    |> String.replace(~r{([\\,;])}, "\\\\\\g{1}")
    |> String.replace("\n", ~S"\n")
  end

  def to_ics(x) when is_integer(x), do: Integer.to_string(x)
  def to_ics(x) when is_float(x), do: Float.to_string(x)

  # Convert DateTimes to UTC then into ics-format strings
  def to_ics(%DateTime{} = timestamp) do
    format_string = "{YYYY}{0M}{0D}T{h24}{m}{s}"

    {:ok, result} =
      timestamp
      |> Timex.format(format_string)

    result
  end

  # Convert Dates to UTC then into ics-format strings
  def to_ics(%Date{} = timestamp) do
    format_string = "{YYYY}{0M}{0D}"

    {:ok, result} =
      timestamp
      |> Timex.format(format_string)

    result
  end

  # This function converts Erlang timestamp tuples into DateTimes.
  def to_ics({{year, month, day}, {hour, minute, second}} = timestamp)
      when is_integer(year) and
             is_integer(month) and month <= 12 and month >= 1 and
             is_integer(day) and day <= 31 and day >= 1 and
             is_integer(hour) and hour <= 23 and hour >= 0 and
             is_integer(minute) and minute <= 59 and minute >= 0 and
             is_integer(second) and second <= 59 and second >= 0 do
    timestamp
    |> Timex.to_datetime()
    |> to_ics()
  end

  def to_ics(x), do: x
end
