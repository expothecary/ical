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
    case to_weekday(value) do
      :error -> recurrence
      {weekday_atom, _} -> %{recurrence | weekday: weekday_atom}
    end
  end

  defp add_to_recurrence(_, recurrence), do: recurrence

  # all of these keywords start with "BY", so we look for that first
  # and then parse into which one it is. these all map to bounded
  # sets of numbres, except BYDAY which is extra complicated.
  # see to_weekdays for more on that.
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
    number_list = to_weekdays(value)
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
    case Deserialize.to_integer(value) do
      nil -> recurrence
      number -> Map.put(recurrence, key, number)
    end
  end

  defp to_clamped_numbers(string, min, max) do
    to_clamped_numbers(string, min, max, "", [])
  end

  defp to_clamped_numbers(<<>>, min, max, value, acc) do
    clamp_number(value, min, max, acc)
  end

  defp to_clamped_numbers(<<?,, string::binary>>, min, max, value, acc) do
    acc = clamp_number(value, min, max, acc)
    to_clamped_numbers(string, min, max, "", acc)
  end

  defp to_clamped_numbers(<<c, string::binary>>, min, max, value, acc) do
    to_clamped_numbers(string, min, max, <<value::binary, c>>, acc)
  end

  defp clamp_number(value, min, max, acc) do
    # zeros are only allowed when the min value is also zero:
    # a negative min means no zeros, and if the min is above zero, obviously
    # zero is not ok
    case Deserialize.to_integer(value) do
      0 when min == 0 ->
        acc ++ [0]

      number when is_number(number) and number != 0 and number <= max and number >= min ->
        acc ++ [number]

      _ ->
        acc
    end
  end

  # Weekdays are two-letter abbreviations for the 7 English days of the week
  # optionally preceded by #, +#, or -# which indicates that they are the Nth of that
  # day, e.g. -1MO in a month recurrance would mean the last Monday of the month.
  # Yes, it's insane, but so is everything about iCalendar.
  defp to_weekdays(string), do: to_weekdays(string, [])

  # as usual, check for end of string before we get started
  defp to_weekdays(<<>>, acc), do: acc

  # commas are always separators, so we reset when we find one
  defp to_weekdays(<<?,, string::binary>>, acc), do: to_weekdays(string, acc)

  # here we check for the optional +/-# and if we find one we parse for an offset weekday
  defp to_weekdays(<<?+, string::binary>>, acc), do: to_offset_weekdays(string, <<>>, acc)
  defp to_weekdays(<<?-, string::binary>>, acc), do: to_offset_weekdays(string, <<?->>, acc)

  defp to_weekdays(<<n, string::binary>>, acc) when n >= ?0 and n <= ?9 do
    to_offset_weekdays(string, <<n>>, acc)
  end

  # no offset, so just send it in with a 0 for the offset, which the user will ignore
  # in a {0, someweekday} tuple
  defp to_weekdays(string, acc) do
    to_weekday_with_offset(string, nil, acc)
  end

  # doing an entry with an offset, and we have more numbers,  so keep going
  defp to_offset_weekdays(<<n::utf8, string::binary>>, offset, acc) when n >= ?0 and n <= ?9 do
    to_offset_weekdays(string, <<offset::binary, n::utf8>>, acc)
  end

  # done with nubmers? parse our number and then get the weekday
  defp to_offset_weekdays(string, offset, acc) do
    offset = String.to_integer(offset)
    to_weekday_with_offset(string, offset, acc)
  end

  # here we try to map the weekday string to a valid value. if it works, we have  {#, atom} tuple
  # otherwise, drop this value as it is broken, and move on to the next parse
  defp to_weekday_with_offset(string, offset, acc) do
    case to_weekday(string) do
      {weekday, string} -> to_weekdays(string, acc ++ [{offset, weekday}])
      :error -> to_weekdays(skip_to_comma(string), acc)
    end
  end

  # motor on through to the comma
  defp skip_to_comma(<<>>), do: <<>>
  defp skip_to_comma(<<?,, string::binary>>), do: string
  defp skip_to_comma(<<_::utf8, string::binary>>), do: skip_to_comma(string)

  # map the two-letter abbreviations to atoms
  defp to_weekday(<<"SU", rest::binary>>), do: {:sunday, rest}
  defp to_weekday(<<"MO", rest::binary>>), do: {:monday, rest}
  defp to_weekday(<<"TU", rest::binary>>), do: {:tuesday, rest}
  defp to_weekday(<<"WE", rest::binary>>), do: {:wednesday, rest}
  defp to_weekday(<<"TH", rest::binary>>), do: {:thursday, rest}
  defp to_weekday(<<"FR", rest::binary>>), do: {:friday, rest}
  defp to_weekday(<<"SA", rest::binary>>), do: {:saturday, rest}
  defp to_weekday(_), do: :error

  # map the frequency strings to atoms, or error out
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
