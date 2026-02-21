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
    acc ++ [Serialize.date_to_ics("CREATED", value)]
  end

  defp to_ics({:dtstamp, value}, acc) do
    stamp = if value == nil, do: DateTime.utc_now(), else: value

    acc ++ [Serialize.date_to_ics("DTSTAMP", stamp)]
  end

  defp to_ics({:dtend, value}, acc) do
    acc ++ [Serialize.date_to_ics("DTEND", value)]
  end

  defp to_ics({:dtstart, value}, acc) do
    acc ++ [Serialize.date_to_ics("DTSTART", value)]
  end

  defp to_ics({:duration, value}, acc) do
    acc ++ [to_text_kv("DURATION", Serialize.to_ics(value))]
  end

  defp to_ics({:exdates, value}, acc) when is_list(value) do
    acc ++ [Enum.map(value, &Serialize.date_to_ics("EXDATE", &1))]
  end

  defp to_ics({:geo, _} = geo, acc) do
    acc ++ Serialize.to_ics(geo)
  end

  defp to_ics({:resources, value}, acc) do
    acc ++ [Serialize.to_comma_list_kv("RESOURCES", value)]
  end

  defp to_ics({:request_status, values}, acc) do
    acc ++ Enum.map(values, fn status -> Serialize.RequestStatus.to_ics(status) end)
  end

  defp to_ics({:rdates, dates}, acc) when is_list(dates) do
    Serialize.Rdate.to_ics(dates, acc)
  end

  defp to_ics({:related_to, value}, acc) do
    acc ++ [Enum.map(value, &to_text_kv("RELATED-TO", &1))]
  end

  defp to_ics({:transparency, value}, acc) do
    value = if value == :transparent, do: "TRANSPARENT", else: "OPAQUE"

    acc ++ [to_text_kv("TRANSP", value)]
  end

  defp to_ics({:recurrence_id, value}, acc) do
    acc ++ [Serialize.date_to_ics("RECURRENCE-ID", value)]
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
