defmodule ICalendar.Event do
  @moduledoc """
  Calendars have events.
  """

  defstruct uid: nil,
            created: nil,
            dtstart: nil,
            dtend: nil,
            dtstamp: nil,
            modified: nil,
            recurrence_id: nil,
            exdates: [],
            rdates: [],
            rrule: nil,
            class: nil,
            description: nil,
            duration: nil,
            location: nil,
            prodid: nil,
            status: nil,
            organizer: nil,
            sequence: nil,
            summary: nil,
            url: nil,
            geo: nil,
            priority: nil,
            transparency: nil,
            attendees: [],
            attachments: [],
            categories: [],
            comments: [],
            contacts: [],
            related_to: [],
            resources: []

  @type t :: %__MODULE__{
          uid: String.t() | nil,
          created: DateTime.t() | nil,
          dtstart: DateTime.t() | nil,
          dtend: DateTime.t() | nil,
          dtstamp: DateTime.t() | nil,
          modified: Date.t() | nil,
          recurrence_id: Date.t() | nil,
          exdates: [DateTime.t()],
          rdates: [DateTime.t()],
          rrule: map() | nil,
          class: String.t() | nil,
          description: String.t() | nil,
          duration: String.t() | nil,
          location: String.t() | nil,
          organizer: String.t() | nil,
          prodid: String.t() | nil,
          sequence: String.t() | nil,
          status: String.t() | nil,
          summary: String.t() | nil,
          url: String.t() | nil,
          geo: {float, float} | nil,
          priority: integer | nil,
          transparency: :opaque | :transparent | nil,
          attachments: [ICalendar.Attachment.t()],
          attendees: [String.t()],
          categories: [String.t()],
          comments: [String.t()],
          contacts: [String.t()],
          related_to: [String.t()],
          resources: [String.t()]
        }
end

defimpl ICalendar.Serialize, for: ICalendar.Event do
  alias ICalendar.Value

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
    entries =
      Enum.map(attendees, fn attendee ->
        params = Map.delete(attendee, :original_value)
        to_parameterized_text_kv("ATTENDEE", params, attendee.original_value)
      end)

    [entries | acc]
  end

  defp to_kv({:categories, value}, acc) do
    [to_comma_list_kv("CATEGORIES", value) | acc]
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
    [["GEO:", to_string(lat), ";", to_string(lon), "\n"] | acc]
  end

  defp to_kv({:resources, value}, acc) do
    [to_comma_list_kv("RESOURCES", value) | acc]
  end

  defp to_kv({:rdates, value}, acc) when is_list(value) do
    [Enum.map(value, &to_date_kv("RDATE", &1)) | acc]
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

    ["RRULE:FREQ=", frequency, other_rrules, "\n" | acc]
  end

  defp to_kv({:status, value}, acc) do
    case value do
      :tentative -> ["STATUS:TENTATIVE\n" | acc]
      :confirmed -> ["STATUS:CONFIRMED\n" | acc]
      :cancelled -> ["STATUS:CANCELLED\n" | acc]
      value when is_binary(value) -> [to_text_kv("STATUS:", value) | acc]
      _ -> acc
    end
  end

  defp to_kv({key, value}, acc) when is_number(value) do
    name = atom_to_value(key)
    [[name, ":", to_string(value), "\n"] | acc]
  end

  defp to_kv({key, value}, acc) when is_atom(value) do
    name = atom_to_value(key)
    value = atom_to_value(value)
    [[name, ":", to_string(value), "\n"] | acc]
  end

  defp to_kv({key, value}, acc) do
    name = atom_to_value(key)
    [to_text_kv(name, value) | acc]
  end

  defp to_text_kv(key, value) do
    [key, ":", Value.to_ics(value), "\n"]
  end

  defp to_parameterized_text_kv(key, params, value) do
    for {param, param_value} <- params do
      [";", param, "=", Value.to_ics(param_value)]
    end

    [key, params, ":", Value.to_ics(value), "\n"]
  end

  def to_date_kv(key, %Date{} = date) do
    [key, ":", Value.to_ics(date), "\n"]
  end

  def to_date_kv(key, %DateTime{time_zone: "Etc/UTC"} = date) do
    [key, ":", Value.to_ics(date), "Z\n"]
  end

  def to_date_kv(key, %DateTime{} = date) do
    [key, ";TZID=", date.time_zone, ":", Value.to_ics(date), "\n"]
  end

  defp to_attachment_kv(%ICalendar.Attachment{} = attachment) do
    params =
      if attachment.mimetype != nil do
        [";FMTTYPE=", attachment.mimetype]
      end

    {encoding_params, value} =
      case attachment.data_type do
        :uri -> {nil, attachment.data}
        :cid -> {nil, ["CID:", attachment.data]}
        :base64 -> {";ENCODING=BASE64;VALUE=BINARY", attachment.data}
        :base8 -> {";ENCODING=8BIT;VALUE=BINARY", attachment.data}
      end

    ["ATTACH", params, encoding_params, ":", value]
  end

  defp to_comma_list_kv(key, values) do
    [key, ":", to_comma_list(values), "\n"]
  end

  defp to_rrule_entry({key, _} = rrule) do
    [";", atom_to_value(key), "=", rrule_value(rrule)]
  end

  defp rrule_value({:until, value}), do: Value.to_ics(value)

  defp rrule_value({_key, values}) when is_list(values) do
    values
    |> Enum.map(&Value.to_ics/1)
    |> Enum.intersperse(",")
  end

  defp rrule_value({_key, value}), do: Value.to_ics(value)

  defp to_comma_list(values) do
    values
    |> Enum.map(&Value.to_ics/1)
    |> Enum.intersperse(",")
  end

  defp atom_to_value(atom) do
    atom |> to_string |> String.upcase()
  end
end
