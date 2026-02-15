defmodule ICal.Serialize.Recurrence do
  @moduledoc false

  alias ICal.Serialize

  def to_ics(%ICal.Recurrence{} = recurrence, acc) do
    rules =
      Enum.reduce(Map.from_struct(recurrence), [], &to_rrule_entry/2)

    [["RRULE:FREQ=", Serialize.to_ics(recurrence.frequency), rules, ?\n] | acc]
  end

  def to_ics(%{freq: frequency} = recurrence, acc) do
    rules = Enum.reduce(recurrence, [], &to_rrule_entry/2)
    [["RRULE:FREQ=", frequency, rules, ?\n] | acc]
  end

  def to_ics(_, acc), do: acc

  # frequency is done "manually" as the first entry
  defp to_rrule_entry({:freq, _}, acc), do: acc
  defp to_rrule_entry({:frequency, _}, acc), do: acc

  # skip empty entries
  defp to_rrule_entry({_, nil}, acc), do: acc

  # everything else!
  defp to_rrule_entry({key, _} = rrule, acc) do
    string_key = key_to_string(key)
    acc ++ [?;, string_key, ?=, rrule_value(rrule)]
  end

  #   defp rrule_value({:until, value}), do: Serialize.to_ics(value)

  # byday entries have {#, atom} tuples
  defp rrule_value({:by_day, entries}) do
    Enum.map(
      entries,
      fn
        {0, weekday} -> to_weekday(weekday)
        {number, weekday} -> [to_string(number), to_weekday(weekday)]
      end
    )
  end

  defp rrule_value({_key, values}) when is_list(values) do
    values
    |> Enum.map(&Serialize.to_ics/1)
    |> Enum.intersperse(?,)
  end

  defp rrule_value({_key, value}), do: Serialize.to_ics(value)

  defp to_weekday(:monday), do: "MO"
  defp to_weekday(:tuesday), do: "TU"
  defp to_weekday(:wednesday), do: "WE"
  defp to_weekday(:thursday), do: "TH"
  defp to_weekday(:friday), do: "FR"
  defp to_weekday(:saturday), do: "SA"
  defp to_weekday(:sunday), do: "SU"

  defp key_to_string(:until), do: "UNTIL"
  defp key_to_string(:count), do: "COUNT"
  defp key_to_string(:by_second), do: "BYSECOND"
  defp key_to_string(:by_minute), do: "BYMINUTE"
  defp key_to_string(:by_hour), do: "BYHOUR"
  defp key_to_string(:by_day), do: "BYDAY"
  defp key_to_string(:by_month_day), do: "BYMONTHDAY"
  defp key_to_string(:by_year_day), do: "BYYEARDAY"
  defp key_to_string(:by_month), do: "BYMONTH"
  defp key_to_string(:by_set_position), do: "BYSETPOS"
  defp key_to_string(:by_week_number), do: "BYWEEKNO"
  defp key_to_string(:weekday), do: "WKST"
  defp key_to_string(:frequency), do: "FREQ"
  defp key_to_string(:interval), do: "INTERVAL"
  defp key_to_string(key), do: Serialize.atom_to_value(key)
end
