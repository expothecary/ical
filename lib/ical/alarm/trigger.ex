defmodule ICal.Alarm.Trigger do
  defstruct [:relative_to, :on, repeat: 0]

  @type t :: %__MODULE__{
          repeat: non_neg_integer,
          relative_to: :start | :end | nil,
          on: DateTime.t() | ICal.Duration.t()
        }
end
