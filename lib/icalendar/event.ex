defmodule ICalendar.Event do
  @moduledoc """
  Calendars have events.
  """

  defstruct summary: nil,
            created: nil,
            dtstart: nil,
            dtend: nil,
            rrule: nil,
            exdates: [],
            recurrence_id: nil,
            dtstamp: nil,
            description: nil,
            location: nil,
            url: nil,
            uid: nil,
            prodid: nil,
            status: nil,
            categories: [],
            class: nil,
            comment: nil,
            geo: nil,
            modified: nil,
            organizer: nil,
            sequence: nil,
            attendees: [],
            priority: nil,
            transparency: nil,
            duration: nil,
            attachments: [],
            contacts: [],
            related_to: [],
            resources: [],
            rdates: []

  @type t :: %__MODULE__{
          summary: String.t() | nil,
          created: DateTime.t() | nil,
          dtstart: DateTime.t() | nil,
          dtend: DateTime.t() | nil,
          rrule: String.t() | nil,
          exdates: [DateTime.t()],
          recurrence_id: String.t() | nil,
          dtstamp: DateTime.t() | nil,
          description: String.t() | nil,
          location: String.t() | nil,
          url: String.t() | nil,
          uid: String.t() | nil,
          prodid: String.t() | nil,
          status: String.t() | nil,
          categories: [String.t()],
          class: String.t() | nil,
          comment: String.t() | nil,
          geo: {float, float} | nil,
          modified: String.t() | nil,
          organizer: String.t() | nil,
          sequence: String.t() | nil,
          attendees: [String.t()],
          priority: integer | nil,
          transparency: :opaque | :transparent | nil,
          duration: String.t() | nil,
          attachments: [ICalendar.Attachment.t()],
          contacts: [String.t()],
          related_to: [String.t()],
          resources: [String.t()],
          rdates: [DateTime.t()]
        }
end

defimpl ICalendar.Serialize, for: ICalendar.Event do
  alias ICalendar.Util.KV

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

  defp to_kv({:exdates, value}, acc) when is_list(value) do
    [Enum.map(value, &KV.build("EXDATE", &1)) | acc]
  end

  defp to_kv({:recurrence_id, value}, acc) do
    [KV.build("RECURRENCE-ID", value) | acc]
  end

  defp to_kv({:status, value}, acc) when is_list(value) do
    case value do
      :tentative -> ["STATUS:TENTATIVE" | acc]
      :confirmed -> ["STATUS:CONFIRMED" | acc]
      :cancelled -> ["STATUS:CANCELLED" | acc]
      value when is_binary(value) -> ["STATUS:#{value}" | acc]
      _ -> acc
    end
  end

  defp to_kv({key, value}, acc) do
    name = key |> to_string |> String.upcase()
    [KV.build(name, value) | acc]
  end
end
