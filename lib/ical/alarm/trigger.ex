defmodule ICal.Alarm.Trigger do
  @moduledoc """
  An alarm trigger with when to fire the alarm on (a duration from the event or
  an absolute time), whether it is relative to the start or end of time of the
  event in the case of a duration offset, and how many times to repeat it after
  the first alarm.
  """
  defstruct [:relative_to, :on, repeat: 0]

  @type t :: %__MODULE__{
          repeat: non_neg_integer,
          relative_to: :start | :end | nil,
          on: DateTime.t() | ICal.Duration.t()
        }
end
