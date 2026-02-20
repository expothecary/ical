defmodule ICal.Todo do
  @moduledoc """
  An iCalendar TODO component.

  Note that all the `DateTime.t()` fields in TODOs are in the "Etc/UTC"
  timezone as per RFC5545.
  """

  defstruct [
    :dtstamp,
    :uid,
    class: nil,
    completed: nil,
    created: nil,
    description: nil,
    dtstart: nil,
    geo: nil,
    last_modified: nil,
    location: nil,
    organizer: nil,
    percent: 0,
    priority: 0,
    recurrance_id: nil,
    sequence: 0,
    status: nil,
    summary: nil,
    url: nil,
    rrule: nil,
    due: nil,
    duration: nil,
    attachments: [],
    attendees: [],
    categories: [],
    comments: [],
    contacts: [],
    exdates: [],
    rstatus: [],
    related: [],
    resources: [],
    rdates: [],
    custom_properties: %{}
  ]

  @type maybe :: %__MODULE__{}

  @type t :: %__MODULE__{
          dtstamp: DateTime.t(),
          uid: String.t(),
          class: nil | String.t(),
          completed: nil | DateTime.t(),
          created: nil | DateTime.t(),
          description: nil | String.t(),
          dtstart: nil | DateTime.t() | Date.t(),
          geo: nil | ICal.geo(),
          last_modified: nil | DateTime.t(),
          location: nil | String.t(),
          organizer: nil | String.t(),
          percent: non_neg_integer,
          priority: non_neg_integer,
          recurrance_id: nil | DateTime.t() | Date.t(),
          sequence: non_neg_integer,
          status: nil | String.t(),
          summary: nil | String.t(),
          url: nil | String.t(),
          rrule: nil | ICal.Recurrence.t(),
          due: nil | DateTime.t() | Date.t(),
          duration: nil | ICal.Duration.t(),
          attachments: [ICal.Attachment.t()],
          attendees: [ICal.Attendee.t()],
          categories: [String.t()],
          comments: [String.t()],
          contacts: [ICal.Contact.t()],
          exdates: [Date.t() | DateTime.t()],
          rstatus: [String.t()],
          related: [String.t()],
          resources: [String.t()],
          rdates: [Date.t() | DateTime.t() | ICal.period()],
          custom_properties: ICal.custom_properties()
        }
end
