defmodule ICal.Alarm.Email do
  defstruct attachments: [],
            attendees: [],
            description: "",
            summary: ""

  @type t :: %__MODULE__{
          attachments: [ICal.Attachment.t()],
          attendees: [ICal.Attendee.t()],
          description: String.t(),
          summary: String.t()
        }
end
