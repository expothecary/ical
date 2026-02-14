defmodule ICal.Alarm.Display do
  defstruct description: nil

  @type t :: %__MODULE__{
          description: String.t() | nil
        }
end
