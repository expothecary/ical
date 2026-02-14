defmodule ICal.Alarm do
  @moduledoc """
  An iCalendar Alarm
  """
  alias __MODULE__.{Audio, Display, Email, Trigger}

  defstruct trigger: nil,
            properties: nil,
            custom_properties: []

  @type t :: %__MODULE__{
          trigger: Trigger.t(),
          properties: Audio.t() | Display.t() | Email.t(),
          custom_properties: ICal.custom_properties()
        }
end
