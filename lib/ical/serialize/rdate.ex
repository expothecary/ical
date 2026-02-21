defmodule ICal.Serialize.Rdate do
  @moduledoc false

  alias ICal.Serialize

  def property(dates, acc) do
    # reduce the rdates by timezone, so the minimal set of entries gets written out
    # this also separateds out periods, dates, and datetimes as the VALUE= needs to be
    # different for each
    rdates_by_tz = Enum.reduce(dates, %{}, &by_tz/2)
    Enum.reduce(rdates_by_tz, acc, &to_rdate_ics/2)
  end

  defp by_tz({from, to}, acc) do
    serialized = [[Serialize.value(from), ?/, Serialize.value(to)]]

    Map.update(acc, {:periods, from.time_zone}, serialized, fn periods ->
      periods ++ serialized
    end)
  end

  defp by_tz(%Date{} = date, acc) do
    serialized = [Serialize.value(date)]

    Map.update(acc, :dates, serialized, fn dates -> dates ++ serialized end)
  end

  defp by_tz(%DateTime{} = date, acc) do
    serialized = [Serialize.value(date)]

    Map.update(acc, date.time_zone, serialized, fn dates ->
      dates ++ serialized
    end)
  end

  defp to_rdate_ics({:dates, periods}, acc) do
    acc ++ ["RDATE;VALUE=DATE:", Enum.intersperse(periods, ?,), ?\n]
  end

  defp to_rdate_ics({{:periods, "Etc/UTC"}, periods}, acc) do
    acc ++ ["RDATE;VALUE=PERIOD:", Enum.intersperse(periods, ?,), ?\n]
  end

  defp to_rdate_ics({{:periods, tz}, periods}, acc) do
    acc ++ ["RDATE;VALUE=PERIOD;TZID=", tz, ?:, Enum.intersperse(periods, ?,), ?\n]
  end

  defp to_rdate_ics({"Etc/UTC", dates}, acc) do
    acc ++ ["RDATE:", Enum.intersperse(dates, ?,), ?\n]
  end

  defp to_rdate_ics({tz, dates}, acc) do
    acc ++ ["RDATE;TZID=", tz, ?:, Enum.intersperse(dates, ?,), ?\n]
  end
end
