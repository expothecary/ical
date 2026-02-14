defmodule ICal.Deserialize.Macros do
  @moduledoc false

  defmacro append(a, b) do
    quote do
      <<unquote(a)::binary, unquote(b)::utf8>>
    end
  end
end

defmodule ICal.Deserialize do
  @moduledoc false
  import __MODULE__.Macros

  def rest_of_key(<<?\r, ?\n, data::binary>>, key), do: {data, key}
  def rest_of_key(<<?\n, data::binary>>, key), do: {data, key}
  def rest_of_key(<<?;, _::binary>> = data, key), do: {data, key}

  def rest_of_key(<<?:, _::binary>> = data, key), do: {data, key}

  def rest_of_key(<<c::utf8, data::binary>>, key) do
    rest_of_key(data, <<key::binary, c::utf8>>)
  end

  def comma_separated_list(data), do: comma_separated_list(data, "", [])
  defp comma_separated_list(<<>> = data, "", acc), do: {data, acc}
  defp comma_separated_list(<<>> = data, value, acc), do: {data, acc ++ [value]}

  defp comma_separated_list(<<?\r, ?\n, data::binary>>, value, acc) do
    if value == "", do: {data, acc}, else: {data, acc ++ [value]}
  end

  defp comma_separated_list(<<?\n, data::binary>>, value, acc) do
    if value == "", do: {data, acc}, else: {data, acc ++ [value]}
  end

  defp comma_separated_list(<<"\\n", data::binary>>, value, acc) do
    comma_separated_list(data, append(value, ?\n), acc)
  end

  defp comma_separated_list(<<?\\, c::utf8, data::binary>>, value, acc) do
    comma_separated_list(data, append(value, c), acc)
  end

  defp comma_separated_list(<<?,, data::binary>>, "", acc) do
    comma_separated_list(data, "", acc)
  end

  defp comma_separated_list(<<?,, data::binary>>, value, acc) do
    comma_separated_list(data, "", acc ++ [value])
  end

  defp comma_separated_list(<<c::utf8, data::binary>>, value, acc) do
    comma_separated_list(data, append(value, c), acc)
  end

  def multi_line(data, separator \\ " "), do: multi_line(data, separator, " ", [])

  defp multi_line(data, separator, trim_char, acc) do
    {data, line} = rest_of_line(data)

    acc = add_trimmed(line, trim_char, acc)

    # peek ahead to see if there is more multi-line data
    case data do
      <<?\t, data::binary>> ->
        multi_line(data, separator, "\t", acc)

      <<" ", data::binary>> ->
        multi_line(data, separator, " ", acc)

      data ->
        value =
          case acc do
            [] ->
              nil

            lines ->
              lines
              |> Enum.reverse()
              |> Enum.join(separator)
          end

        {data, value}
    end
  end

  defp add_trimmed(nil, _trim_char, acc), do: acc
  defp add_trimmed(line, trim_char, acc), do: [String.trim_leading(line, trim_char) | acc]

  def rest_of_line(<<?\r, ?\n, data::binary>>), do: {data, nil}
  def rest_of_line(<<?\n, data::binary>>), do: {data, nil}
  def rest_of_line(<<>> = data), do: {data, nil}
  def rest_of_line(data), do: rest_of_line(data, <<>>)

  defp rest_of_line(<<>> = data, acc), do: {data, acc}

  defp rest_of_line(<<"\\n", data::binary>>, acc) do
    rest_of_line(data, append(acc, ?\n))
  end

  defp rest_of_line(<<?\\, c::utf8, data::binary>>, acc) do
    rest_of_line(data, append(acc, c))
  end

  defp rest_of_line(<<?\r, ?\n, data::binary>>, acc), do: {data, acc}
  defp rest_of_line(<<?\n, data::binary>>, acc), do: {data, acc}

  defp rest_of_line(<<c::utf8, data::binary>>, acc) do
    rest_of_line(data, append(acc, c))
  end

  # Skipping params allows motoring through the parameters section without
  # complex parsing or allocation of data. e.g. this is an optimization.
  def skip_params(<<>> = data), do: data
  def skip_params(<<?\n, _::binary>> = data), do: data
  def skip_params(<<?\r, ?\n, _::binary>> = data), do: data
  def skip_params(<<?", data::binary>>), do: skip_param_quoted_section(data)

  def skip_params(<<?\\, _::utf8, data::binary>>) do
    skip_params(data)
  end

  def skip_params(<<?:, data::binary>>), do: data

  def skip_params(<<_::utf8, data::binary>>) do
    skip_params(data)
  end

  defp skip_param_quoted_section(<<>> = data), do: data
  defp skip_param_quoted_section(<<?\n, data::binary>>), do: data

  defp skip_param_quoted_section(<<?\\, _::utf8, data::binary>>) do
    skip_param_quoted_section(data)
  end

  defp skip_param_quoted_section(<<?", data::binary>>), do: skip_params(data)

  defp skip_param_quoted_section(<<_::utf8, data::binary>>) do
    skip_param_quoted_section(data)
  end

  # used to get parameters applied to keys, e.g. KEY;PARAMS...:VALUE
  def params(<<?;, data::binary>>), do: params(data, <<>>, %{})
  def params(<<?:, data::binary>>), do: {data, %{}}
  def params(data), do: {data, %{}}

  # used to get parameter-list formatted *values*
  def param_list(data), do: params(data, <<>>, %{})

  defp params(<<>> = data, _val, params), do: {data, params}
  defp params(<<?\n, _::binary>> = data, _val, params), do: {data, params}
  defp params(<<?r, ?\n, _::binary>> = data, _val, params), do: {data, params}

  defp params(<<?\\, c::utf8, data::binary>>, val, params) do
    params(data, append(val, c), params)
  end

  defp params(<<?;, data::binary>>, val, params) do
    params(data, <<>>, Map.put(params, val, ""))
  end

  defp params(<<?:, data::binary>>, val, params), do: {data, Map.put(params, val, "")}

  defp params(<<?=, ?", data::binary>>, val, params) do
    param_value_quoted(data, val, <<>>, params)
  end

  defp params(<<?=, data::binary>>, val, params), do: param_value(data, val, <<>>, params)
  defp params(<<c::utf8, data::binary>>, val, params), do: params(data, append(val, c), params)

  # a param value goes to the end of the data, the line, or until an unescaped `:` character.
  # an unescaped `;` also stops the value, but signals that another parameter is next
  defp param_value(<<>> = data, key, val, params), do: {data, Map.put(params, key, val)}

  defp param_value(<<?\r, ?\n, data::binary>>, key, val, params),
    do: {data, Map.put(params, key, val)}

  defp param_value(<<?\n, data::binary>>, key, val, params), do: {data, Map.put(params, key, val)}

  defp param_value(<<"\\n", data::binary>>, key, val, params) do
    param_value(data, key, append(val, ?\n), params)
  end

  defp param_value(<<?\\, c::utf8, data::binary>>, key, val, params) do
    param_value(data, key, append(val, c), params)
  end

  defp param_value(<<?:, data::binary>>, key, val, params), do: {data, Map.put(params, key, val)}

  # another param starts, so recurse to params again
  defp param_value(<<?;, data::binary>>, key, val, params) do
    params(data, <<>>, Map.put(params, key, val))
  end

  defp param_value(<<c::utf8, data::binary>>, key, val, params) do
    param_value(data, key, append(val, c), params)
  end

  # a quoted param value is the same as a param value, with the added complication
  # that it is quoted, so it does not really end until a matching unquoted `"`.
  # if a `;` is encountered, there is another parameter that follows
  defp param_value_quoted(<<>> = data, key, val, params) do
    {data, add_quote_value_to_params(params, key, val)}
  end

  defp param_value_quoted(<<?\r, ?\n, data::binary>>, key, val, params) do
    {data, add_quote_value_to_params(params, key, val)}
  end

  defp param_value_quoted(<<?\n, data::binary>>, key, val, params) do
    {data, add_quote_value_to_params(params, key, val)}
  end

  defp param_value_quoted(<<"\\n", data::binary>>, key, val, params) do
    param_value_quoted(data, key, append(val, ?\n), params)
  end

  defp param_value_quoted(<<?\\, c::utf8, data::binary>>, key, val, params) do
    param_value_quoted(data, key, append(val, c), params)
  end

  # this is not only a quoted parameter, but a LIST of quoted parameters
  # at this point, call into `param_value_quoted_list` to start building a list
  defp param_value_quoted(<<?", ?,, ?", data::binary>>, key, val, params) do
    param_value_quoted_list(data, key, val, params)
  end

  # done!
  defp param_value_quoted(<<?", ?:, data::binary>>, key, val, params) do
    {data, add_quote_value_to_params(params, key, val)}
  end

  # another param detect, so recurse to params again
  defp param_value_quoted(<<?", ?;, data::binary>>, key, val, params) do
    params(data, <<>>, add_quote_value_to_params(params, key, val))
  end

  defp param_value_quoted(<<c::utf8, data::binary>>, key, val, params) do
    param_value_quoted(data, key, append(val, c), params)
  end

  # since it may be a quoted *list*, check to see if there is a list started
  # and if so add the value to the key
  defp add_quote_value_to_params(params, key, val) do
    case Map.get(params, key) do
      acc when is_list(acc) ->
        Map.put(params, key, acc ++ [val])

      _current ->
        Map.put(params, key, val)
    end
  end

  defp param_value_quoted_list(data, key, val, params) do
    # this function enters with an entry in acc
    current_val = Map.get(params, key, [])
    params = Map.put(params, key, current_val ++ [val])
    param_value_quoted(data, key, <<>>, params)
  end

  def skip_line(<<>> = data), do: data
  def skip_line(<<?\r, ?\n, data::binary>>), do: data
  def skip_line(<<?\n, data::binary>>), do: data
  def skip_line(<<_::utf8, data::binary>>), do: skip_line(data)

  def parse_geo(data) do
    with [lat, lon] <- String.split(data, ";", parts: 2),
         {lat_f, ""} when lat_f >= -90 and lat_f <= 90 <- Float.parse(lat),
         {lon_f, ""} when lon_f >= -180 and lon_f <= 180 <- Float.parse(lon) do
      {lat_f, lon_f}
    else
      _ -> nil
    end
  end

  def to_timezone(timezone, default \\ "Etc/UTC")
  def to_timezone(nil, default), do: default

  def to_timezone(timezone, default) do
    cond do
      String.contains?(timezone, "/") -> timezone
      Timex.Timezone.Utils.to_olson(timezone) != nil -> Timex.Timezone.Utils.to_olson(timezone)
      true -> default
    end
  end

  @doc """
  This function is designed to parse iCal datetime strings into erlang dates.

  It should be able to handle dates from the past:

      iex> {:ok, date} = ICal.Util.Deserialize.to_date("19930407T153022Z")
      ...> Timex.to_erl(date)
      {{1993, 4, 7}, {15, 30, 22}}

  As well as the future:

      iex> {:ok, date} = ICal.Util.Deserialize.to_date("39930407T153022Z")
      ...> Timex.to_erl(date)
      {{3993, 4, 7}, {15, 30, 22}}

  And should return error for incorrect dates:

      iex> ICal.Util.Deserialize.to_date("1993/04/07")
      {:error, "Expected `2 digit month` at line 1, column 5."}

  It should handle timezones from  the Olson Database:

      iex> {:ok, date} = ICal.Util.Deserialize.to_date("19980119T020000",
      ...> %{"TZID" => "America/Chicago"})
      ...> [Timex.to_erl(date), date.time_zone]
      [{{1998, 1, 19}, {2, 0, 0}}, "America/Chicago"]
  """
  def to_date(nil, _params, _calendar), do: nil

  def to_date(date_string, %{"TZID" => timezone}, %ICal{default_timezone: default_timezone}) do
    # Microsoft Outlook calendar .ICS files report times in Greenwich Standard Time (UTC +0)
    # so just convert this to UTC
    timezone = to_timezone(timezone, default_timezone)
    to_date_with_timezone(date_string, timezone)
  end

  def to_date(date_string, %{"VALUE" => "DATE"}, %ICal{default_timezone: default_timezone}) do
    to_date_with_timezone(date_string <> "T000000Z", default_timezone)
  end

  def to_date(date_string, _params, %ICal{default_timezone: default_timezone}) do
    to_date_with_timezone(date_string, default_timezone)
  end

  defp to_date_with_timezone(date_string, timezone) do
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
end
