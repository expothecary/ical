defmodule ICal.Alarm.Email do
  defstruct attachment: nil,
            attendees: [],
            description: "",
            summary: ""

  @type t :: %__MODULE__{
          attachment: ICal.Attachment.t(),
          attendees: [ICal.Attendee.t()],
          description: String.t(),
          summary: String.t()
        }
end
