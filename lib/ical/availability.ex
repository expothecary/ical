defmodule ICal.Availability do
  @moduledoc """
  An iCalendar Availability (`VAVAILABILITY`), defined by
  [RFC 7953](https://www.rfc-editor.org/rfc/rfc7953.html).

  A `VAVAILABILITY` component describes when a calendar user is available to
  be scheduled. Within the period it covers, time defaults to the component's
  `busytype` — `:busy_unavailable` unless stated otherwise — and each
  `ICal.Availability.Available` subcomponent carves out a period of *free*
  time within it.

  The period covered is `dtstart` to `dtend` (or `dtstart` plus `duration`).
  Either endpoint may be absent, in which case that side is unbounded, and a
  component with neither covers all time.

  Where two `VAVAILABILITY` components overlap, `priority` decides which
  applies: 1 is the highest priority and 9 the lowest, while 0 or `nil` means
  no priority was set and ranks below all of them.
  """

  defstruct uid: nil,
            dtstamp: nil,
            created: nil,
            dtstart: nil,
            dtend: nil,
            duration: nil,
            modified: nil,
            busytype: :busy_unavailable,
            priority: nil,
            class: nil,
            description: nil,
            location: nil,
            organizer: nil,
            sequence: nil,
            summary: nil,
            url: nil,
            available: [],
            categories: [],
            comments: [],
            contacts: [],
            custom_properties: %{}

  @typedoc """
  The kind of busy time the component asserts outside its `AVAILABLE`
  subcomponents. Tokens other than the three RFC 7953 defines are kept
  verbatim as a string.
  """
  @type busytype :: :busy | :busy_unavailable | :busy_tentative | String.t()

  @type t :: %__MODULE__{
          uid: String.t() | nil,
          dtstamp: ICal.optional_rfc5455_datetime(),
          created: ICal.optional_rfc5455_datetime(),
          dtstart: ICal.optional_rfc5455_date(),
          dtend: ICal.optional_rfc5455_date(),
          duration: ICal.Duration.t() | nil,
          modified: ICal.optional_rfc5455_date(),
          busytype: busytype(),
          priority: integer | nil,
          class: String.t() | nil,
          description: String.t() | nil,
          location: String.t() | nil,
          organizer: String.t() | nil,
          sequence: String.t() | nil,
          summary: String.t() | nil,
          url: String.t() | nil,
          available: [ICal.Availability.Available.t()],
          categories: [String.t()],
          comments: [String.t()],
          contacts: [ICal.Contact.t()],
          custom_properties: ICal.custom_properties()
        }
end
