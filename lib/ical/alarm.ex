defmodule ICal.Alarm do
  @moduledoc """
  An iCalendar Alarm
  """
  alias __MODULE__.{Audio, Custom, Display, Email, Trigger}

  defstruct action: %Custom{}, trigger: %Trigger{}, custom_properties: %{}

  @type t :: %__MODULE__{
          trigger: Trigger.t(),
          action: Audio.t() | Display.t() | Email.t() | Custom.t(),
          custom_properties: ICal.custom_properties()
        }
end
