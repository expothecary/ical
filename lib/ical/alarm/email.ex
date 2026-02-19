defmodule ICal.Alarm.Email do
  @moduledoc "An email alarm with attendees (receipients), description, summary, and optional attachments"

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
