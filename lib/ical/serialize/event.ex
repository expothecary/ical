defmodule ICal.Serialize.Event do
  @moduledoc false

  alias ICal.Serialize

  def to_ics(event) do
    contents =
      event
      |> Map.from_struct()
      |> Enum.reduce([], &to_ics/2)

    [
      "BEGIN:VEVENT\n",
      contents,
      "END:VEVENT\n"
    ]
  end

  defp to_ics({_key, ""}, acc), do: acc
  defp to_ics({key, nil}, acc) when key != :dtstamp, do: acc
  defp to_ics({_key, []}, acc), do: acc

  defp to_ics({:attachments, value}, acc) do
    acc ++ [Enum.map(value, &Serialize.Attachment.to_ics/1)]
  end

  defp to_ics({:attendees, attendees}, acc) do
    entries = Enum.map(attendees, &Serialize.Attendee.to_ics/1)
    acc ++ [entries]
  end

  defp to_ics({:alarms, alarms}, acc) do
    entries = Enum.map(alarms, &Serialize.Alarm.to_ics/1)
    acc ++ [entries]
  end

  defp to_ics({:custom_properties, custom_properties}, acc) do
    Serialize.add_custom_properties(acc, custom_properties)
  end

  defp to_ics({:categories, value}, acc) do
    acc ++ [Serialize.to_comma_list_kv("CATEGORIES", value)]
  end

  defp to_ics({:comments, value}, acc) do
    acc ++ [Enum.map(value, &to_text_kv("COMMENT", &1))]
  end

  defp to_ics({:contacts, value}, acc) do
    acc ++ [Enum.map(value, &Serialize.Contact.to_ics(&1))]
  end

  defp to_ics({:created, value}, acc) do
    acc ++ [to_date_kv("CREATED", value)]
  end

  defp to_ics({:dtstamp, value}, acc) do
    stamp = if value == nil, do: DateTime.utc_now(), else: value

    acc ++ [to_date_kv("DTSTAMP", stamp)]
  end

  defp to_ics({:dtend, value}, acc) do
    acc ++ [to_date_kv("DTEND", value)]
  end

  defp to_ics({:dtstart, value}, acc) do
    acc ++ [to_date_kv("DTSTART", value)]
  end

  defp to_ics({:duration, value}, acc) do
    acc ++ [to_text_kv("DURATION", Serialize.to_ics(value))]
  end

  defp to_ics({:exdates, value}, acc) when is_list(value) do
    acc ++ [Enum.map(value, &to_date_kv("EXDATE", &1))]
  end

  defp to_ics({:geo, _} = geo, acc) do
    acc ++ Serialize.to_ics(geo)
  end

  defp to_ics({:resources, value}, acc) do
    [Serialize.to_comma_list_kv("RESOURCES", value) | acc]
  end

  defp to_ics({:rdates, dates}, acc) when is_list(dates) do
    # reduce the rdates by timezone, so the minimal set of entries gets written out
    # this also separateds out periods, dates, and datetimes as the VALUE= needs to be
    # different for each
    rdates_by_tz =
      Enum.reduce(
        dates,
        %{},
        fn
          {from, to}, acc ->
            serialized = [[Serialize.to_ics(from), ?/, Serialize.to_ics(to)]]

            Map.update(acc, {:periods, from.time_zone}, serialized, fn periods ->
              periods ++ serialized
            end)

          %Date{} = date, acc ->
            serialized = [Serialize.to_ics(date)]

            Map.update(acc, :dates, serialized, fn dates -> dates ++ serialized end)

          %DateTime{} = date, acc ->
            serialized = [Serialize.to_ics(date)]

            Map.update(acc, date.time_zone, serialized, fn dates ->
              dates ++ serialized
            end)
        end
      )

    Enum.reduce(rdates_by_tz, acc, &to_rdate_ics/2)
  end

  defp to_ics({:related_to, value}, acc) do
    acc ++ [Enum.map(value, &to_text_kv("RELATED-TO", &1))]
  end

  defp to_ics({:transparency, value}, acc) do
    value = if value == :transparent, do: "TRANSPARENT", else: "OPAQUE"

    acc ++ [to_text_kv("TRANSP", value)]
  end

  defp to_ics({:recurrence_id, value}, acc) do
    acc ++ [to_date_kv("RECURRENCE-ID", value)]
  end

  defp to_ics({:rrule, rule}, acc) do
    acc ++ Serialize.Recurrence.to_ics(rule)
  end

  defp to_ics({:status, value}, acc) do
    acc ++
      case value do
        :tentative -> ["STATUS:TENTATIVE\n"]
        :confirmed -> ["STATUS:CONFIRMED\n"]
        :cancelled -> ["STATUS:CANCELLED\n"]
        value -> [to_text_kv("STATUS", to_string(value))]
      end
  end

  defp to_ics({key, value}, acc) when is_number(value) do
    name = Serialize.atom_to_value(key)
    acc ++ [name, ?:, to_string(value), ?\n]
  end

  defp to_ics({key, value}, acc) when is_atom(value) do
    name = Serialize.atom_to_value(key)
    value = Serialize.atom_to_value(value)
    acc ++ [name, ?:, to_string(value), ?\n]
  end

  defp to_ics({key, value}, acc) do
    name = Serialize.atom_to_value(key)
    acc ++ [to_text_kv(name, value)]
  end

  defp to_text_kv(key, value) do
    [key, ?:, Serialize.to_ics(value), ?\n]
  end

  def to_date_kv(key, %Date{} = date) do
    [key, ";VALUE=DATE:", Serialize.to_ics(date), ?\n]
  end

  def to_date_kv(key, %DateTime{time_zone: "Etc/UTC"} = date) do
    [key, ?:, Serialize.to_ics(date), ?\n]
  end

  def to_date_kv(key, %DateTime{} = date) do
    [key, ";TZID=", date.time_zone, ?:, Serialize.to_ics(date), ?\n]
  end

  defp to_rdate_ics({:dates, periods}, acc),
    do: acc ++ ["RDATE;VALUE=DATE:", Enum.intersperse(periods, ?,), ?\n]

  defp to_rdate_ics({{:periods, "Etc/UTC"}, periods}, acc),
    do: acc ++ ["RDATE;VALUE=PERIOD:", Enum.intersperse(periods, ?,), ?\n]

  defp to_rdate_ics({{:periods, tz}, periods}, acc),
    do: acc ++ ["RDATE;VALUE=PERIOD;TZID=", tz, ?:, Enum.intersperse(periods, ?,), ?\n]

  defp to_rdate_ics({"Etc/UTC", dates}, acc),
    do: acc ++ ["RDATE:", Enum.intersperse(dates, ?,), ?\n]

  defp to_rdate_ics({tz, dates}, acc),
    do: acc ++ ["RDATE;TZID=", tz, ?:, Enum.intersperse(dates, ?,), ?\n]
end
