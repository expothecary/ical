defmodule ICalendar.Serialize.Event do
  @moduledoc false

  alias ICalendar.Serialize

  def to_ics(event) do
    contents = to_kvs(event)

    [
      "BEGIN:VEVENT\n",
      contents,
      "END:VEVENT\n"
    ]
  end

  defp to_kvs(event) do
    event
    |> Map.from_struct()
    |> Enum.reduce([], &to_kv/2)
  end

  defp to_kv({_key, ""}, acc), do: acc
  defp to_kv({key, nil}, acc) when key != :dtstamp, do: acc
  defp to_kv({_key, []}, acc), do: acc

  defp to_kv({:attachments, value}, acc) do
    [Enum.map(value, &to_attachment_kv/1) | acc]
  end

  defp to_kv({:attendees, attendees}, acc) do
    entries = Enum.map(attendees, &ICalendar.Serialize.Attendee.to_ics/1)
    [entries | acc]
  end

  defp to_kv({:categories, value}, acc) do
    [Serialize.to_comma_list_kv("CATEGORIES", value) | acc]
  end

  defp to_kv({:comments, value}, acc) do
    [Enum.map(value, &to_text_kv("COMMENT", &1)) | acc]
  end

  defp to_kv({:contacts, value}, acc) do
    [Enum.map(value, &to_text_kv("CONTACT", &1)) | acc]
  end

  defp to_kv({:created, value}, acc) do
    [to_date_kv("CREATED", value) | acc]
  end

  defp to_kv({:dtstamp, value}, acc) do
    stamp = if value == nil, do: DateTime.utc_now(), else: value

    [to_date_kv("DTSTAMP", stamp) | acc]
  end

  defp to_kv({:dtend, value}, acc) do
    [to_date_kv("DTEND", value) | acc]
  end

  defp to_kv({:dtstart, value}, acc) do
    [to_date_kv("DTSTART", value) | acc]
  end

  defp to_kv({:exdates, value}, acc) when is_list(value) do
    [Enum.map(value, &to_date_kv("EXDATE", &1)) | acc]
  end

  defp to_kv({:geo, {lat, lon}}, acc) do
    [["GEO:", to_string(lat), ?;, to_string(lon), ?\n] | acc]
  end

  defp to_kv({:resources, value}, acc) do
    [Serialize.to_comma_list_kv("RESOURCES", value) | acc]
  end

  defp to_kv({:rdates, values}, acc) when is_list(values) do
    # TODO: put this on the same line if they are identical types? e.g. all dates
    # with the same tz together, etc.
    [Enum.map(values, &to_date_kv("RDATE", &1)) | acc]
  end

  defp to_kv({:related_to, value}, acc) do
    [Enum.map(value, &to_text_kv("RELATED-TO", &1)) | acc]
  end

  defp to_kv({:transparency, value}, acc) do
    value = if value == :transparent, do: "TRANSPARENT", else: "OPAQUE"

    [to_text_kv("TRANSP", value) | acc]
  end

  defp to_kv({:recurrence_id, value}, acc) do
    [to_date_kv("RECURRENCE-ID", value) | acc]
  end

  defp to_kv({:rrule, rrules}, acc) when is_map(rrules) do
    # FREQ rule part MUST be the first rule part specified in a RECUR value.
    frequency = Map.get(rrules, :freq, "DAILY")

    other_rrules =
      rrules
      |> Map.delete(:freq)
      |> Enum.map(&to_rrule_entry/1)

    ["RRULE:FREQ=", frequency, other_rrules, ?\n | acc]
  end

  defp to_kv({:status, value}, acc) do
    case value do
      :tentative -> ["STATUS:TENTATIVE\n" | acc]
      :confirmed -> ["STATUS:CONFIRMED\n" | acc]
      :cancelled -> ["STATUS:CANCELLED\n" | acc]
      value -> [to_text_kv("STATUS", to_string(value)) | acc]
    end
  end

  defp to_kv({key, value}, acc) when is_number(value) do
    name = Serialize.atom_to_value(key)
    [[name, ?:, to_string(value), ?\n] | acc]
  end

  defp to_kv({key, value}, acc) when is_atom(value) do
    name = Serialize.atom_to_value(key)
    value = Serialize.atom_to_value(value)
    [[name, ?:, to_string(value), ?\n] | acc]
  end

  defp to_kv({key, value}, acc) do
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
    [key, ":", Serialize.to_ics(date), "Z\n"]
  end

  def to_date_kv(key, %DateTime{} = date) do
    [key, ";TZID=", date.time_zone, ?:, Serialize.to_ics(date), ?\n]
  end

  def to_date_kv(key, {from, to}) do
    [key, ";VALUE=PERIOD:", Serialize.to_ics(from), ?/, Serialize.to_ics(to), ?\n]
  end

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
