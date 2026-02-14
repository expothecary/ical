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
            resources: [],
            custom_entries: %{}

  @type period ::
          {from :: DateTime.t(), to :: DateTime.t()}
          | {from :: DateTime.t(), to :: ICalendar.Duration.t()}
  @type t :: %__MODULE__{
          uid: String.t() | nil,
          created: DateTime.t() | nil,
          dtstart: DateTime.t() | nil,
          dtend: DateTime.t() | nil,
          dtstamp: DateTime.t() | nil,
          modified: Date.t() | nil,
          recurrence_id: Date.t() | nil,
          exdates: [DateTime.t()],
          rdates: [DateTime.t() | period],
          rrule: map() | nil,
          class: String.t() | nil,
          description: String.t() | nil,
          duration: ICalendar.Duration.t() | nil,
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
          contacts: [ICalendar.Contact.t()],
          related_to: [String.t()],
          resources: [String.t()],
          custom_entries: ICalendar.custom_entries()
        }

  defdelegate to_ics(calendar), to: ICalendar.Serialize.Event
  defdelegate from_ics(data), to: ICalendar.Deserialize.Event
end
