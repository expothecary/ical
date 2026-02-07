defmodule ICalendar.Event do
  @moduledoc """
  Calendars have events.
  """

  defstruct summary: nil,
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
            categories: nil,
            class: nil,
            comment: nil,
            geo: nil,
            modified: nil,
            organizer: nil,
            sequence: nil,
            attendees: []

  @type t :: %__MODULE__{
          summary: String.t() | nil,
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
          categories: String.t() | nil,
          class: String.t() | nil,
          comment: String.t() | nil,
          geo: {float, float} | nil,
          modified: String.t() | nil,
          organizer: String.t() | nil,
          sequence: String.t() | nil,
          attendees: [String.t()]
        }
end

defimpl ICalendar.Serialize, for: ICalendar.Event do
  alias ICalendar.Util.KV

  def to_ics(event, _options \\ []) do
    contents = to_kvs(event)

    """
    BEGIN:VEVENT
    #{contents}END:VEVENT
    """
  end

  defp to_kvs(event) do
    event
    |> Map.from_struct()
    |> Enum.map(&to_kv/1)
    |> List.flatten()
    |> Enum.sort()
    |> Enum.join()
  end

  defp to_kv({:exdates, value}) when is_list(value) do
    case value do
      [] ->
        ""

      exdates ->
        exdates
        |> Enum.map(&KV.build("EXDATE", &1))
    end
  end

  defp to_kv({:recurrence_id, value}) do
    KV.build("RECURRENCE-ID", value)
  end

  defp to_kv({:status, value}) when is_list(value) do
    case value do
      :tentative -> "STATUS:TENTATIVE"
      :confirmed -> "STATUS:CONFIRMED"
      :cancelled -> "STATUS:CANCELLED"
      value when is_binary(value) -> "STATUS:#{value}"
      _ -> ""
    end
  end

  defp to_kv({key, value}) do
    name = key |> to_string |> String.upcase()
    KV.build(name, value)
  end
end
