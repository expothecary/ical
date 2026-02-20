defmodule ICal.Timezone do
  @moduledoc """
  An iCalendar Timezone component
  """

  defmodule Properties do
    @moduledoc "The detailed properties of a timezone component"
    defstruct [
      :dtstart,
      offsets: %{from: 0, to: 0},
      rrule: nil,
      comments: [],
      rdates: [],
      names: [],
      custom_properties: []
    ]

    @type t :: %__MODULE__{
            dtstart: NaiveDateTime.t(),
            offsets: %{from: integer(), to: integer()},
            rrule: ICal.Recurrence.t() | nil,
            comments: [String.t()],
            rdates: [NaiveDateTime.t()],
            names: [String.t()],
            custom_properties: ICal.custom_properties()
          }
  end

  defstruct [
    :id,
    standard: [],
    daylight: [],
    last_modified: nil,
    url: nil,
    custom_properties: []
  ]

  @type t :: %__MODULE__{
          id: String.t(),
          standard: __MODULE__.Properties.t(),
          daylight: __MODULE__.Properties.t(),
          last_modified: DateTime.t() | nil,
          url: String.t() | nil,
          custom_properties: ICal.custom_properties()
        }
end
