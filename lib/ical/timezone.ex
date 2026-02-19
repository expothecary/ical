defmodule ICal.Timezone do
  @moduledoc """
  An iCalendar Timezone component
  """

  defmodule Properties do
    @moduledoc "The detailed properties of a timezone component"
    defstruct [
      :dtstart,
      :tzoffset,
      rrule: nil,
      comment: [],
      rdate: [],
      tzname: [],
      custom_properties: []
    ]

    @type t :: %__MODULE__{
            dtstart: DateTime.t(),
            tzoffset: %{from: integer(), to: integer()},
            rrule: ICal.Recurrence.t() | nil,
            comment: [String.t()],
            rdate: [DateTime.t()],
            tzname: [String.t()],
            custom_properties: ICal.custom_properties()
          }
  end

  defstruct [
    :tzid,
    standard: [],
    daylight: [],
    last_modified: nil,
    tzurl: nil,
    custom_properties: []
  ]

  @type t :: %__MODULE__{
          tzid: String.t(),
          standard: __MODULE__.Properties.t(),
          daylight: __MODULE__.Properties.t(),
          last_modified: DateTime.t() | nil,
          tzurl: String.t() | nil,
          custom_properties: ICal.custom_properties()
        }
end
