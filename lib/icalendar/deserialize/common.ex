defmodule ICalendar.Deserialize.Common.Macros do
  @moduledoc false

  defmacro append(a, b) do
    quote do
      <<unquote(a)::binary, unquote(b)::utf8>>
    end
  end
end

defmodule ICalendar.Deserialize.Common do
  @moduledoc false
  import __MODULE__.Macros

  def multi_line(data), do: multi_line(data, <<>>)

  defp multi_line(data, acc) do
    {data, line} = rest_of_line(data)
    val = acc <> " " <> line

    case data do
      <<?\t, data::binary>> -> multi_line(data, val)
      data -> {data, val}
    end
  end

  def rest_of_line(data), do: rest_of_line(data, <<>>)
  defp rest_of_line(<<>> = data, acc), do: {data, acc}

  defp rest_of_line(<<?\\, c::utf8, data::binary>>, acc) do
    rest_of_line(data, append(acc, c))
  end

  defp rest_of_line(<<?\n, data::binary>>, acc), do: {data, acc}

  defp rest_of_line(<<c::utf8, data::binary>>, acc) do
    rest_of_line(data, append(acc, c))
  end

  def params(<<?;, data::binary>>), do: params(data, <<>>, %{})
  def params(data), do: params(data, <<>>, %{})

  defp params(<<>> = data, _val, params), do: {data, params}
  defp params(<<?\n, data::binary>>, _val, params), do: {data, params}

  defp params(<<?\\, c::utf8, data::binary>>, val, params) do
    params(data, append(val, c), params)
  end

  defp params(<<?:, data::binary>>, _val, params), do: {data, params}
  defp params(<<?=, data::binary>>, val, params), do: param_value(data, val, <<>>, params)
  defp params(<<c::utf8, data::binary>>, val, params), do: params(data, append(val, c), params)

  defp param_value(<<?:, data::binary>>, key, val, params), do: {data, Map.put(params, key, val)}
  defp param_value(<<>> = data, key, val, params), do: {data, Map.put(params, key, val)}
  defp param_value(<<?\n, data::binary>>, key, val, params), do: {data, Map.put(params, key, val)}

  defp param_value(<<?\\, c::utf8, data::binary>>, key, val, params) do
    param_value(data, key, append(val, c), params)
  end

  defp param_value(<<?;, data::binary>>, key, val, params) do
    params(data, <<>>, Map.put(params, key, val))
  end

  defp param_value(<<c::utf8, data::binary>>, key, val, params) do
    param_value(data, key, append(val, c), params)
  end

  def consume_line(<<>> = data), do: data
  def consume_line(<<?\n, data::binary>>), do: data
  def consume_line(<<_::utf8, data::binary>>), do: consume_line(data)

  @doc """
  This function is designed to parse iCal datetime strings into erlang dates.

  It should be able to handle dates from the past:

      iex> {:ok, date} = ICalendar.Util.Deserialize.to_date("19930407T153022Z")
      ...> Timex.to_erl(date)
      {{1993, 4, 7}, {15, 30, 22}}

  As well as the future:

      iex> {:ok, date} = ICalendar.Util.Deserialize.to_date("39930407T153022Z")
      ...> Timex.to_erl(date)
      {{3993, 4, 7}, {15, 30, 22}}

  And should return error for incorrect dates:

      iex> ICalendar.Util.Deserialize.to_date("1993/04/07")
      {:error, "Expected `2 digit month` at line 1, column 5."}

  It should handle timezones from  the Olson Database:

      iex> {:ok, date} = ICalendar.Util.Deserialize.to_date("19980119T020000",
      ...> %{"TZID" => "America/Chicago"})
      ...> [Timex.to_erl(date), date.time_zone]
      [{{1998, 1, 19}, {2, 0, 0}}, "America/Chicago"]
  """
  def to_date(date_string, %{"TZID" => timezone}) do
    # Microsoft Outlook calendar .ICS files report times in Greenwich Standard Time (UTC +0)
    # so just convert this to UTC
    timezone =
      if Regex.match?(~r/\//, timezone) do
        timezone
      else
        Timex.Timezone.Utils.to_olson(timezone)
      end

    with_timezone =
      if String.ends_with?(date_string, "Z") do
        date_string <> timezone
      else
        date_string <> "Z" <> timezone
      end

    case Timex.parse(with_timezone, "{YYYY}{0M}{0D}T{h24}{m}{s}Z{Zname}") do
      {:ok, date} -> date
      _ -> nil
    end
  end

  def to_date(date_string, %{"VALUE" => "DATE"}) do
    to_date(date_string <> "T000000Z")
  end

  def to_date(date_string, %{}) do
    to_date(date_string, %{"TZID" => "Etc/UTC"})
  end

  def to_date(date_string) do
    to_date(date_string, %{"TZID" => "Etc/UTC"})
  end
end
