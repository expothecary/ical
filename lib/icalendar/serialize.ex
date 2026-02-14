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
  def to_ics(%DateTime{} = date_time) do
    format_string =
      if date_time.time_zone == "Etc/UTC" do
        "{YYYY}{0M}{0D}T{h24}{m}{s}Z"
      else
        "{YYYY}{0M}{0D}T{h24}{m}{s}"
      end

    {:ok, result} = Timex.format(date_time, format_string)

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
  # credo:disable-for-next-line
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

  def to_ics(%ICalendar.Duration{} = duration) do
    ICalendar.Serialize.Duration.to_ics(duration)
  end

  def to_ics(x), do: x

  def escaped_quotes(x) do
    String.replace(x, ~S|"|, ~S|\"|)
  end

  # create a key/value pair with a comma-separated list
  def to_comma_list_kv(key, values) do
    [key, ":", to_comma_list(values), "\n"]
  end

  # creates a conformant comma-separated list
  def to_comma_list(values) do
    values
    |> Enum.map(&to_ics/1)
    |> Enum.intersperse(",")
  end

  def atom_to_value(atom) do
    atom |> to_string |> String.upcase()
  end

  def to_quoted_value(value) do
    [?", escaped_quotes(value), ?"]
  end

  # creates a conformant comma-separated list
  def to_quoted_comma_list(values) do
    values
    |> Enum.map(&to_quoted_value/1)
    |> Enum.intersperse(",")
  end
end
