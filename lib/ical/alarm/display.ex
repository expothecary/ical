defmodule ICal.Alarm.Display do
  defstruct description: "", duration: nil

  @type t :: %__MODULE__{
          description: String.t(),
          duration: ICal.Duration.t() | nil
        }
end
