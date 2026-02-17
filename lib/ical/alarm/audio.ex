defmodule ICal.Alarm.Audio do
  @moduledoc "An audio alarm with optional attachments and duration"

  defstruct [:duration, :attachments, repeat: 0]

  @type t :: %__MODULE__{
          attachments: [ICal.Attachment.t()],
          duration: ICal.Duration.t() | nil
        }
end
