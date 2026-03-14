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
  # this module contains a small library of functions shared between
  # different modules that do parsing
  import __MODULE__.Macros

  def attachment(data) do
    {data, params} = params(data)
    {data, value} = value(data)

    attachment =
      case params do
        %{"ENCODING" => "BASE64", "VALUE" => "BINARY"} ->
          %ICal.Attachment{data_type: :base64, data: value}

        %{"ENCODING" => "8BIT", "VALUE" => "BINARY"} ->
          %ICal.Attachment{data_type: :base8, data: value}

        _params ->
          case value do
            <<"CID:", cid::binary>> -> %ICal.Attachment{data_type: :cid, data: cid}
            value -> %ICal.Attachment{data_type: :uri, data: value}
          end
      end
      |> Map.put(:mimetype, Map.get(params, "FMTTYPE"))

    {data, attachment}
  end

  def gather_unrecognized_component(<<>> = data, _end_tag, acc), do: {data, acc}

  def gather_unrecognized_component(data, end_tag, acc) do
    if String.starts_with?(data, end_tag) do
      length = byte_size(end_tag)
      <<_::binary-size(length), rest::binary>> = data
      {rest, acc ++ [end_tag]}
    else
      {data, key} = rest_of_key(data, "")
      {data, params} = params(data)
      {data, value} = value(data)
      gather_unrecognized_component(data, end_tag, acc ++ [{key, params, value}])
    end
  end

  # this fetch the rest of a key, e.g. from some part near the start
  # of a line to the first ; (signalling params) or : (signaling value)
  def rest_of_key(<<?\r, ?\n, data::binary>>, key), do: {data, key}
  def rest_of_key(<<?\n, data::binary>>, key), do: {data, key}
  def rest_of_key(<<?;, _::binary>> = data, key), do: {data, key}

  def rest_of_key(<<?:, _::binary>> = data, key), do: {data, key}

  def rest_of_key(<<c::utf8, data::binary>>, key) do
    rest_of_key(data, <<key::binary, c::utf8>>)
  end

  # this parses out a comma separated list. they can have \-escaped
  # entries, escaped newlines, ... it should also skip over malformations
  # such as empty entries
  def comma_separated_list(data), do: comma_separated_list(data, "", [])
  defp comma_separated_list(<<>> = data, "", acc), do: {data, acc}
  defp comma_separated_list(<<>> = data, value, acc), do: {data, acc ++ [value]}

  defp comma_separated_list(<<?\n, data::binary>>, value, acc) do
    continue_on_line_fold(data, accumulate_if_not_empty(acc, value), :comma_separated_list)
  end

  defp comma_separated_list(<<?\r, ?\n, data::binary>>, value, acc) do
    continue_on_line_fold(data, accumulate_if_not_empty(acc, value), :comma_separated_list)
  end

  defp comma_separated_list(<<?\\, ?n, data::binary>>, value, acc) do
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

  defp accumulate_if_not_empty(acc, ""), do: acc
  defp accumulate_if_not_empty(acc, value), do: acc ++ List.wrap(value)

  def value(data) do
    case value(data, <<>>) do
      {data, <<>>} -> {data, nil}
      value -> value
    end
  end

  defp value(data, acc) do
    {data, acc} = rest_of_line(data, acc)
    continue_on_line_fold(data, acc, &value/2)
  end

  # end of data
  defp rest_of_line(<<>> = data, acc), do: {data, acc}

  # a literal \n, so turn it into a newline, per the spec
  defp rest_of_line(<<?\\, ?n, data::binary>>, acc) do
    rest_of_line(data, append(acc, ?\n))
  end

  # escaped character!
  defp rest_of_line(<<?\\, c::utf8, data::binary>>, acc) do
    rest_of_line(data, append(acc, c))
  end

  # both kinds of new lines signal we are done
  defp rest_of_line(<<?\n, data::binary>>, acc), do: {data, acc}
  defp rest_of_line(<<?\r, ?\n, data::binary>>, acc), do: {data, acc}

  # not done yet, take a character and keep moving
  defp rest_of_line(<<c::utf8, data::binary>>, acc) do
    rest_of_line(data, append(acc, c))
  end

  # Skipping params allows motoring through the parameters section without
  # complex parsing or allocation of data. e.g. this is an optimization.
  def skip_params(<<>> = data), do: data

  def skip_params(<<?\n, _::binary>> = data) do
    continue_on_line_fold(data, :no_value, &skip_params/1)
  end

  def skip_params(<<?\r, ?\n, _::binary>> = data) do
    continue_on_line_fold(data, :no_value, &skip_params/1)
  end

  def skip_params(<<?", data::binary>>), do: skip_param_quoted_section(data)

  # escaped characters!
  def skip_params(<<?\\, _::utf8, data::binary>>) do
    skip_params(data)
  end

  # the : means we have reach the value. note that an escape colon is caught
  # in the previous function header
  def skip_params(<<?:, data::binary>>), do: data

  def skip_params(<<_::utf8, data::binary>>) do
    skip_params(data)
  end

  defp skip_param_quoted_section(<<>> = data), do: data

  defp skip_param_quoted_section(<<?\n, data::binary>>) do
    continue_on_line_fold(data, :no_value, &skip_param_quoted_section/1)
  end

  defp skip_param_quoted_section(<<?\\, _::utf8, data::binary>>) do
    skip_param_quoted_section(data)
  end

  defp skip_param_quoted_section(<<?", data::binary>>), do: skip_params(data)

  defp skip_param_quoted_section(<<_::utf8, data::binary>>) do
    skip_param_quoted_section(data)
  end

  # used to get parameter-list formatted *values*
  # this is where the value of an entry is formated the same way
  # a paramter list is. e.g. RRULE, aka recurrence rules
  # this can't use the regular params/1 function since that
  # insists on starting with a ';' as per the spec
  def param_list(data), do: params(data, <<>>, %{})

  # used to get parameters applied to keys, e.g. KEY;PARAMS=VALUE...:VALUE
  # these are tricky as they can be quoted, have escapes, and more
  # if we start with a ';' just skip it
  def params(<<?;, data::binary>>), do: params(data, <<>>, %{})
  # if we start with a ':', we hav eno params
  def params(<<?:, data::binary>>), do: {data, %{}}
  # we have no params, but also no value .. return anyways!
  def params(data), do: {data, %{}}

  # called on multi-line continuation
  defp params(data, params), do: params(data, <<>>, params)

  # parse the actual list of params, first checking for end of buffer or line
  defp params(<<>> = data, _val, params), do: {data, params}

  defp params(<<?\n, _::binary>> = data, _val, params) do
    continue_on_line_fold(data, params, &params/2)
  end

  defp params(<<?r, ?\n, _::binary>> = data, _val, params) do
    continue_on_line_fold(data, params, &params/2)
  end

  # escaped character!
  defp params(<<?\\, c::utf8, data::binary>>, val, params) do
    params(data, append(val, c), params)
  end

  # a ';' means this parameter is complete, and a new one should begin
  # paramters with no values get an empty string for consistency
  defp params(<<?;, data::binary>>, val, params) do
    params(data, <<>>, Map.put(params, val, ""))
  end

  # a ":" means we've hit a value entry and are done, similar to new lines.
  defp params(<<?:, data::binary>>, val, params), do: {data, Map.put(params, val, "")}

  # the '=' means we have the key for the entry, and now need to look for value
  # in this case the value is between "s, so parse a *quoted* value
  defp params(<<?=, ?", data::binary>>, key, params) do
    quoted_param(data, key, params)
  end

  # in this case, it's just a normal value, so start parsing that without looking for "s
  defp params(<<?=, data::binary>>, key, params) do
    {data, value} = param_value(data, <<>>)

    case value do
      {:next_param, value} ->
        params(data, <<>>, Map.put(params, key, value))

      value ->
        {data, Map.put(params, key, value)}
    end
  end

  # more data, add it to the accumulator and keep moving
  defp params(<<c::utf8, data::binary>>, val, params), do: params(data, append(val, c), params)

  # a param value goes to the end of the data, the line, or until an unescaped `:` character.
  # an unescaped `;` also stops the value, but signals that another parameter is next
  defp param_value(<<>> = data, val), do: {data, val}

  # check for end-of-lines
  defp param_value(<<?\n, data::binary>>, val) do
    continue_on_line_fold(data, val, &param_value/2)
  end

  defp param_value(<<?\r, ?\n, data::binary>>, val) do
    continue_on_line_fold(data, val, &param_value/2)
  end

  # convert literal "\n" into a new line
  defp param_value(<<?\\, ?n, data::binary>>, val) do
    param_value(data, append(val, ?\n))
  end

  # escape characters...
  defp param_value(<<?\\, c::utf8, data::binary>>, val) do
    param_value(data, append(val, c))
  end

  # we've hit a value entry, stop here
  defp param_value(<<?:, data::binary>>, val), do: {data, val}

  # another param starts, so recurse to params again
  defp param_value(<<?;, data::binary>>, val) do
    {data, {:next_param, val}}
  end

  # just more data, keep going
  defp param_value(<<c::utf8, data::binary>>, val) do
    param_value(data, append(val, c))
  end

  # quote params can also be lists, so this function allows
  # recursion within lists.
  defp quoted_param(data, key, params) do
    {data, value} = param_value_quoted(data, <<>>)

    case value do
      {:next_list_value, value} ->
        quoted_param(data, key, add_quoted_value_to_params(params, key, value, []))

      {:next_param, value} ->
        params(data, <<>>, add_quoted_value_to_params(params, key, value, nil))

      value ->
        {data, add_quoted_value_to_params(params, key, value, nil)}
    end
  end

  # a quoted param value is the same as a param value, with the added complication
  # that it is quoted, so it does not really end until a matching unquoted `"`.
  # if a `;` is encountered, there is another parameter that follows
  defp param_value_quoted(<<>> = data, val) do
    {data, val}
  end

  defp param_value_quoted(<<?\n, data::binary>>, val) do
    {data, val}
  end

  defp param_value_quoted(<<?\r, ?\n, data::binary>>, val) do
    {data, val}
  end

  defp param_value_quoted(<<?\\, ?n, data::binary>>, val) do
    param_value_quoted(data, append(val, ?\n))
  end

  defp param_value_quoted(<<?\\, c::utf8, data::binary>>, val) do
    param_value_quoted(data, append(val, c))
  end

  # this is not only a quoted parameter, but a LIST of quoted parameters
  defp param_value_quoted(<<?", ?,, ?", data::binary>>, val) do
    {data, {:next_list_value, val}}
  end

  # done!
  defp param_value_quoted(<<?", ?:, data::binary>>, val) do
    {data, val}
  end

  # another param detect, so recurse to params again
  defp param_value_quoted(<<?", ?;, data::binary>>, val) do
    {data, {:next_param, val}}
  end

  defp param_value_quoted(<<c::utf8, data::binary>>, val) do
    param_value_quoted(data, append(val, c))
  end

  # since it may be a quoted *list*, check to see if there is a list started
  # and if so add the value to the key
  defp add_quoted_value_to_params(params, key, val, default) do
    case Map.get(params, key, default) do
      acc when is_list(acc) ->
        Map.put(params, key, acc ++ [val])

      _current ->
        Map.put(params, key, val)
    end
  end

  # just completely skip the line, don't even both collecting the data
  @spec skip_line(binary()) :: binary()
  def skip_line(<<>> = data), do: data
  def skip_line(<<?\n, data::binary>>), do: continue_on_line_fold(data, :no_value, &skip_line/1)

  def skip_line(<<?\r, ?\n, data::binary>>),
    do: continue_on_line_fold(data, :no_value, &skip_line/1)

  def skip_line(<<_::utf8, data::binary>>), do: skip_line(data)

  # continue_on_line_fold checks to see if the first character is a tab or a space
  # and if so, continues the parsing by calling the continuation `fun`
  # with the state, otherwise it simply returns the state.
  #
  # The state is `{data, value}` unless `:no_value` is passed in as the value,
  # in which case the state is just `data`. This allows sharing this code between
  # functions which are simply skipping bytes and not accumulating them, and
  # functions which are accumulating values to be returned.
  @spec continue_on_line_fold(data :: binary, :no_value | binary, function) ::
          {data :: binary, value :: binary} | (data :: binary)
  defp continue_on_line_fold(<<?\t, data::binary>>, value, fun) do
    continue_line(data, value, fun)
  end

  defp continue_on_line_fold(<<?\s, data::binary>>, value, fun) do
    continue_line(data, value, fun)
  end

  defp continue_on_line_fold(data, :no_value, _fun), do: data
  defp continue_on_line_fold(data, value, _fun), do: {data, value}

  defp continue_line(data, :no_value, fun), do: fun.(data)
  defp continue_line(data, value, fun), do: fun.(data, value)

  # this parses a GEO entry, which is a ;-separated tuple of lat/lon
  def parse_geo(data) do
    with [lat, lon] <- String.split(data, ";", parts: 2),
         {lat_f, ""} when lat_f >= -90 and lat_f <= 90 <- Float.parse(lat),
         {lon_f, ""} when lon_f >= -180 and lon_f <= 180 <- Float.parse(lon) do
      {lat_f, lon_f}
    else
      _ -> nil
    end
  end

  # convert a string to a proper timezone, this includes ones with a /
  # but also ones like Central Standard Time, so we try our best to normalize those
  # all else fails, assume UTC
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

      iex> {:ok, date} = ICal.Deserialize.to_date("19930407T153022Z")
      ...> Timex.to_erl(date)
      {{1993, 4, 7}, {15, 30, 22}}

  As well as the future:

      iex> {:ok, date} = ICal.Deserialize.to_date("39930407T153022Z")
      ...> Timex.to_erl(date)
      {{3993, 4, 7}, {15, 30, 22}}

  And should return error for incorrect dates:

      iex> ICal.Util.Deserialize.to_date("1993/04/07")
      {:error, "Expected `2 digit month` at line 1, column 5."}

  It should handle timezones from  the Olson Database:

      iex> {:ok, date} = ICal.Deserialize.to_date("19980119T020000",
      ...> %{"TZID" => "America/Chicago"})
      ...> [Timex.to_erl(date), date.time_zone]
      [{{1998, 1, 19}, {2, 0, 0}}, "America/Chicago"]
  """
  def to_date(nil, _params, _calendar), do: nil

  def to_date(date_string, %{"TZID" => timezone}, %ICal{default_timezone: default_timezone}) do
    # Microsoft Outlook calendar .ICS files report times in Greenwich Standard Time (UTC +0)
    # so just convert this to UTC
    timezone = to_timezone(timezone, default_timezone)
    to_date_in_timezone(date_string, timezone)
  end

  def to_date(date_string, %{"VALUE" => "DATE"}, _calendar) do
    case Timex.parse(date_string, "{YYYY}{0M}{0D}") do
      {:ok, date} -> NaiveDateTime.to_date(date)
      _ -> nil
    end
  end

  def to_date(date_string, _params, %ICal{default_timezone: default_timezone}) do
    to_date_in_timezone(date_string, default_timezone)
  end

  def to_date_in_timezone(date_string, timezone) do
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

  def to_local_date(date_string) do
    case Timex.parse(date_string, "{YYYY}{0M}{0D}T{h24}{m}{s}") do
      {:ok, date} -> date
      _ -> nil
    end
  end

  def to_integer(value, default \\ nil)
  def to_integer(nil, default), do: default
  def to_integer("", default), do: default
  def to_integer(value, _default) when is_number(value), do: value

  def to_integer(value, default) when is_binary(value) do
    case Integer.parse(value) do
      {number, ""} -> number
      _ -> default
    end
  end

  def to_integer(_value, default), do: default

  def status(%ICal.Event{}, "TENTATIVE"), do: :tentative
  def status(%ICal.Event{}, "CONFIRMED"), do: :confirmed
  def status(%ICal.Todo{}, "NEEDS-ACTION"), do: :needs_action
  def status(%ICal.Todo{}, "COMPLETED"), do: :completed
  def status(%ICal.Todo{}, "IN-PROCESS"), do: :in_process
  def status(%ICal.Journal{}, "DRAFT"), do: :draft
  def status(%ICal.Journal{}, "FINAL"), do: :final
  def status(_, "CANCELLED"), do: :cancelled
  def status(_, _), do: nil
end
