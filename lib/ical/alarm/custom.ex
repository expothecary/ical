defmodule ICal.Alarm.Custom do
  defstruct [:type, properties: %{}]

  @type t :: %__MODULE__{
          type: String.t()
        }
end
