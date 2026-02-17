defmodule ICal.Alarm.Display do
  defstruct description: ""

  @type t :: %__MODULE__{
          description: String.t()
        }
end
