defmodule ICal.Todo do
  @moduledoc """
  An iCalendar TODO component.
  """

  # credo:disable-for-next-line
  defstruct [
    :uid,
    :dtstamp,
    created: nil,
    completed: nil,
    dtstart: nil,
    modified: nil,
    recurrance_id: nil,
    exdates: [],
    rdates: [],
    rrule: nil,
    class: nil,
    description: nil,
    duration: nil,
    location: nil,
    status: nil,
    organizer: nil,
    sequence: 0,
    summary: nil,
    url: nil,
    geo: nil,
    priority: 0,
    percent: 0,
    due: nil,
    alarms: [],
    attachments: [],
    attendees: [],
    categories: [],
    comments: [],
    contacts: [],
    related_to: [],
    resources: [],
    request_status: [],
    custom_properties: %{}
  ]

  @type maybe :: %__MODULE__{}

  @type t :: %__MODULE__{
          uid: String.t(),
          dtstamp: DateTime.t(),
          created: nil | DateTime.t(),
          completed: nil | DateTime.t(),
          modified: nil | DateTime.t(),
          recurrance_id: nil | DateTime.t() | Date.t(),
          exdates: [Date.t() | DateTime.t()],
          rdates: [Date.t() | DateTime.t() | ICal.period()],
          class: nil | String.t(),
          description: nil | String.t(),
          dtstart: nil | DateTime.t() | Date.t(),
          geo: nil | ICal.geo(),
          location: nil | String.t(),
          organizer: nil | String.t(),
          percent: non_neg_integer,
          priority: non_neg_integer,
          sequence: non_neg_integer,
          status: nil | String.t(),
          summary: nil | String.t(),
          url: nil | String.t(),
          rrule: nil | ICal.Recurrence.t(),
          due: nil | DateTime.t() | Date.t(),
          duration: nil | ICal.Duration.t(),
          alarms: [ICal.Alarm.t()],
          attachments: [ICal.Attachment.t()],
          attendees: [ICal.Attendee.t()],
          categories: [String.t()],
          comments: [String.t()],
          contacts: [ICal.Contact.t()],
          request_status: [String.t()],
          related_to: [String.t()],
          resources: [String.t()],
          custom_properties: ICal.custom_properties()
        }
end
