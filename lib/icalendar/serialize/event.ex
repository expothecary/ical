defmodule ICalendar.Serialize.Event do
  @moduledoc false

  alias ICalendar.Serialize

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
    [Enum.map(value, &to_attachment_kv/1) | acc]
  end

  defp to_ics({:attendees, attendees}, acc) do
    entries = Enum.map(attendees, &ICalendar.Serialize.Attendee.to_ics/1)
    [entries | acc]
  end

  defp to_ics({:custom_entries, custom_entries}, acc) do
    Serialize.add_custom_entries(acc, custom_entries)
  end

  defp to_ics({:categories, value}, acc) do
    [Serialize.to_comma_list_kv("CATEGORIES", value) | acc]
  end

  defp to_ics({:comments, value}, acc) do
    [Enum.map(value, &to_text_kv("COMMENT", &1)) | acc]
  end

  defp to_ics({:contacts, value}, acc) do
    [Enum.map(value, &Serialize.Contact.to_ics(&1)) | acc]
  end

  defp to_ics({:created, value}, acc) do
    [to_date_kv("CREATED", value) | acc]
  end

  defp to_ics({:dtstamp, value}, acc) do
    stamp = if value == nil, do: DateTime.utc_now(), else: value

    [to_date_kv("DTSTAMP", stamp) | acc]
  end

  defp to_ics({:dtend, value}, acc) do
    [to_date_kv("DTEND", value) | acc]
  end

  defp to_ics({:dtstart, value}, acc) do
    [to_date_kv("DTSTART", value) | acc]
  end

  defp to_ics({:duration, value}, acc) do
    [to_text_kv("DURATION", Serialize.to_ics(value)) | acc]
  end

  defp to_ics({:exdates, value}, acc) when is_list(value) do
    [Enum.map(value, &to_date_kv("EXDATE", &1)) | acc]
  end

  defp to_ics({:geo, {lat, lon}}, acc) do
    [["GEO:", to_string(lat), ?;, to_string(lon), ?\n] | acc]
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
    [Enum.map(value, &to_text_kv("RELATED-TO", &1)) | acc]
  end

  defp to_ics({:transparency, value}, acc) do
    value = if value == :transparent, do: "TRANSPARENT", else: "OPAQUE"

    [to_text_kv("TRANSP", value) | acc]
  end

  defp to_ics({:recurrence_id, value}, acc) do
    [to_date_kv("RECURRENCE-ID", value) | acc]
  end

  defp to_ics({:rrule, rrules}, acc) when is_map(rrules) do
    # FREQ rule part MUST be the first rule part specified in a RECUR value.
    frequency = Map.get(rrules, :freq, "DAILY")

    other_rrules =
      rrules
      |> Map.delete(:freq)
      |> Enum.map(&to_rrule_entry/1)

    ["RRULE:FREQ=", frequency, other_rrules, ?\n | acc]
  end

  defp to_ics({:status, value}, acc) do
    case value do
      :tentative -> ["STATUS:TENTATIVE\n" | acc]
      :confirmed -> ["STATUS:CONFIRMED\n" | acc]
      :cancelled -> ["STATUS:CANCELLED\n" | acc]
      value -> [to_text_kv("STATUS", to_string(value)) | acc]
    end
  end

  defp to_ics({key, value}, acc) when is_number(value) do
    name = Serialize.atom_to_value(key)
    [[name, ?:, to_string(value), ?\n] | acc]
  end

  defp to_ics({key, value}, acc) when is_atom(value) do
    name = Serialize.atom_to_value(key)
    value = Serialize.atom_to_value(value)
    [[name, ?:, to_string(value), ?\n] | acc]
  end

  defp to_ics({key, value}, acc) do
    name = Serialize.atom_to_value(key)
    [to_text_kv(name, value) | acc]
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
    do: [["RDATE;VALUE=DATE:", Enum.intersperse(periods, ?,), ?\n] | acc]

  defp to_rdate_ics({{:periods, "Etc/UTC"}, periods}, acc),
    do: [["RDATE;VALUE=PERIOD:", Enum.intersperse(periods, ?,), ?\n] | acc]

  defp to_rdate_ics({{:periods, tz}, periods}, acc),
    do: [["RDATE;VALUE=PERIOD;TZID=", tz, ?:, Enum.intersperse(periods, ?,), ?\n] | acc]

  defp to_rdate_ics({"Etc/UTC", dates}, acc),
    do: [["RDATE:", Enum.intersperse(dates, ?,), ?\n] | acc]

  defp to_rdate_ics({tz, dates}, acc),
    do: [["RDATE;TZID=", tz, ?:, Enum.intersperse(dates, ?,), ?\n] | acc]

  defp to_attachment_kv(%ICalendar.Attachment{} = attachment) do
    params =
      if attachment.mimetype != nil do
        [";FMTTYPE=", attachment.mimetype]
      else
        []
      end

    value_with_extra_params =
      case attachment.data_type do
        :uri -> [?:, attachment.data]
        :cid -> [":CID:", attachment.data]
        :base64 -> [";ENCODING=BASE64;VALUE=BINARY:", attachment.data]
        :base8 -> [";ENCODING=8BIT;VALUE=BINARY:", attachment.data]
      end

    ["ATTACH", params, value_with_extra_params, ?\n]
  end

  defp to_rrule_entry({key, _} = rrule) do
    [?;, Serialize.atom_to_value(key), "=", rrule_value(rrule)]
  end

  defp rrule_value({:until, value}), do: Serialize.to_ics(value)

  defp rrule_value({_key, values}) when is_list(values) do
    values
    |> Enum.map(&Serialize.to_ics/1)
    |> Enum.intersperse(",")
  end

  defp rrule_value({_key, value}), do: Serialize.to_ics(value)
end
