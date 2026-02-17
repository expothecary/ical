defmodule ICal.Alarm.Display do
  @moduledoc "A diplay alarm with a description and optional duration"

  defstruct description: "", duration: nil

  @type t :: %__MODULE__{
          description: String.t(),
          duration: ICal.Duration.t() | nil
        }
end
