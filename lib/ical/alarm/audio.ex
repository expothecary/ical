defmodule ICal.Alarm.Audio do
  defstruct attachment: nil

  @type t :: %__MODULE__{
          attachment: [ICal.Attachment.t()]
        }
end
