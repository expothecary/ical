defmodule ICal.Journal do
  @moduledoc """
  An iCalendar Journal component.
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
    description: [],
    duration: nil,
    status: nil,
    organizer: nil,
    sequence: 0,
    summary: nil,
    url: nil,
    priority: 0,
    due: nil,
    alarms: [],
    attachments: [],
    attendees: [],
    categories: [],
    comments: [],
    contacts: [],
    related_to: [],
    request_status: [],
    custom_properties: %{}
  ]

  @type maybe :: %__MODULE__{}

  @type t :: %__MODULE__{
          uid: String.t(),
          dtstamp: ICal.rfc5455_datetime,
          created: ICal.maybe_rfc5455_datetime,
          completed: ICal.maybe_rfc5455_datetime,
          modified: ICal.maybe_rfc5455_datetime,
          recurrance_id: ICal.maybe_rfc5455_datetime | Date.t(),
          exdates: [Date.t() | ICal.rfc5455_datetime],
          rdates: [Date.t() | ICal.rfc5455_datetime | ICal.period()],
          class: nil | String.t(),
          description: [String.t()],
          dtstart: ICal.maybe_rfc5455_datetime | Date.t(),
          organizer: nil | String.t(),
          priority: non_neg_integer,
          sequence: non_neg_integer,
          status: :need_action | :completed | :in_process | :cancelled | nil,
          summary: nil | String.t(),
          url: nil | String.t(),
          rrule: nil | ICal.Recurrence.t(),
          due: ICal.maybe_rfc5455_datetime | Date.t(),
          duration: nil | ICal.Duration.t(),
          alarms: [ICal.Alarm.t()],
          attachments: [ICal.Attachment.t()],
          attendees: [ICal.Attendee.t()],
          categories: [String.t()],
          comments: [String.t()],
          contacts: [ICal.Contact.t()],
          request_status: [String.t()],
          related_to: [String.t()],
          custom_properties: ICal.custom_properties()
        }
end
