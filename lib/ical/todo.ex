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
    percent_completed: 0,
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
          dtstamp: ICal.rfc5455_datetime(),
          created: ICal.optional_rfc5455_datetime(),
          completed: ICal.optional_rfc5455_datetime(),
          modified: ICal.optional_rfc5455_datetime(),
          recurrance_id: ICal.optional_rfc5455_date(),
          exdates: [ICal.rfc5455_date()],
          rdates: [ICal.rfc5455_date() | ICal.period()],
          class: nil | String.t(),
          description: nil | String.t(),
          dtstart: ICal.optional_rfc5455_date(),
          geo: nil | ICal.geo(),
          location: nil | String.t(),
          organizer: nil | String.t(),
          percent_completed: non_neg_integer,
          priority: non_neg_integer,
          sequence: non_neg_integer,
          status: :need_action | :completed | :in_process | :cancelled | nil,
          summary: nil | String.t(),
          url: nil | String.t(),
          rrule: nil | ICal.Recurrence.t(),
          due: ICal.optional_rfc5455_date(),
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
