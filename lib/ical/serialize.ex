defmodule ICal.Serialize do
  @moduledoc false
  use Timex

  # Escapes backslashes, commas, semicolons and newlines
  def value(x) when is_binary(x) do
    x
    |> String.replace(~r{([\\,;])}, "\\\\\\g{1}")
    |> String.replace("\n", ~S"\n")
  end

  def value(x) when is_integer(x), do: Integer.to_string(x)
  def value(x) when is_float(x), do: Float.to_string(x)

  # Convert DateTimes into ics-format strings
  # Timezones are dropped if they are not in UTC format as
  # those bleong in the TZID parameter
  def value(%DateTime{} = date_time) do
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
  def value(%Date{} = timestamp) do
    format_string = "{YYYY}{0M}{0D}"

    {:ok, result} =
      timestamp
      |> Timex.format(format_string)

    result
  end

  # Convert NaiveDateTimesinto ics-format strings
  def value(%NaiveDateTime{} = timestamp) do
    format_string = "{YYYY}{0M}{0D}T{h24}{m}{s}"

    {:ok, result} =
      timestamp
      |> Timex.format(format_string)

    result
  end

  # This function converts Erlang timestamp tuples into DateTimes.
  # credo:disable-for-next-line
  def value({{year, month, day}, {hour, minute, second}} = timestamp)
      when is_integer(year) and
             is_integer(month) and month <= 12 and month >= 1 and
             is_integer(day) and day <= 31 and day >= 1 and
             is_integer(hour) and hour <= 23 and hour >= 0 and
             is_integer(minute) and minute <= 59 and minute >= 0 and
             is_integer(second) and second <= 59 and second >= 0 do
    timestamp
    |> Timex.to_datetime()
    |> value()
  end

  def value(%ICal.Duration{} = duration) do
    ICal.Serialize.Duration.property(duration)
  end

  def value({:geo, {lat, lon}}) do
    ["GEO:", to_string(lat), ?;, to_string(lon), ?\n]
  end

  def value(x) when is_atom(x), do: x |> to_string() |> String.upcase()
  def value(x), do: x

  @spec add_custom_properties(iolist(), ICal.custom_properties()) :: iolist()
  def add_custom_properties(acc, custom_properties) do
    Enum.reduce(
      custom_properties,
      acc,
      fn
        {key, %{params: params, value: v}}, acc when is_binary(key) ->
          param_string =
            Enum.map(params, fn {key, v} -> [?;, key, ?=, value(v)] end)

          acc ++ [key, param_string, ?:, v, ?\n]

        _, acc ->
          acc
      end
    )
  end

  def components(components) do
    components
    |> Enum.map(fn component ->
      Enum.map(component, fn
        {key, params, value} ->
          param_ics = Enum.map(params, fn {key, value} -> [?;, key, ?=, value(value)] end)
          [key, param_ics, ?:, value, ?\n]

        line ->
          line
      end)
    end)
  end

  def date(key, %Date{} = date) do
    [key, ";VALUE=DATE:", value(date), ?\n]
  end

  def date(key, %DateTime{time_zone: "Etc/UTC"} = date) do
    [key, ?:, value(date), ?\n]
  end

  def date(key, %DateTime{} = date) do
    [key, ";TZID=", date.time_zone, ?:, value(date), ?\n]
  end

  def kv(key, value) do
    [key, ?:, value(value), ?\n]
  end

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
    |> Enum.map(&value/1)
    |> Enum.intersperse(",")
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
