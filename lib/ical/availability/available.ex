defmodule ICal.Availability.Available do
  @moduledoc """
  An `AVAILABLE` subcomponent of an `ICal.Availability`, defined by
  [RFC 7953](https://www.rfc-editor.org/rfc/rfc7953.html).

  Each subcomponent describes a period of *free* time within the enclosing
  `VAVAILABILITY`. It is shaped like an event: `dtstart` with either `dtend`
  or `duration`, and optionally `rrule`, `rdates` and `exdates` to repeat it.

  Unlike its parent, an `AVAILABLE` subcomponent carries no `priority`,
  `class`, `organizer`, `sequence` or `url` — it states when someone is free,
  not how that fact should be classified or scheduled.
  """

  defstruct uid: nil,
            dtstamp: nil,
            created: nil,
            dtstart: nil,
            dtend: nil,
            duration: nil,
            modified: nil,
            recurrence_id: nil,
            rrule: nil,
            rdates: [],
            exdates: [],
            description: nil,
            location: nil,
            summary: nil,
            categories: [],
            comments: [],
            contacts: [],
            custom_properties: %{}

  @type t :: %__MODULE__{
          uid: String.t() | nil,
          dtstamp: ICal.optional_rfc5455_datetime(),
          created: ICal.optional_rfc5455_datetime(),
          dtstart: ICal.optional_rfc5455_date(),
          dtend: ICal.optional_rfc5455_date(),
          duration: ICal.Duration.t() | nil,
          modified: ICal.optional_rfc5455_date(),
          recurrence_id: ICal.optional_rfc5455_date(),
          rrule: ICal.Recurrence.t() | nil,
          rdates: [Date.t() | ICal.rfc5455_datetime() | ICal.period()],
          exdates: [Date.t() | ICal.rfc5455_datetime()],
          description: String.t() | nil,
          location: String.t() | nil,
          summary: String.t() | nil,
          categories: [String.t()],
          comments: [String.t()],
          contacts: [ICal.Contact.t()],
          custom_properties: ICal.custom_properties()
        }
end
