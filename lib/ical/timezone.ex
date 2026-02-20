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
      custom_properties: %{}
    ]

    @type maybe :: %__MODULE__{}

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
    modified: nil,
    url: nil,
    standard: [],
    daylight: [],
    custom_properties: %{}
  ]

  @type maybe :: %__MODULE__{}

  @type t :: %__MODULE__{
          id: String.t(),
          url: String.t() | nil,
          modified: DateTime.t() | nil,
          standard: [__MODULE__.Properties.t()],
          daylight: [__MODULE__.Properties.t()],
          custom_properties: ICal.custom_properties()
        }
end
