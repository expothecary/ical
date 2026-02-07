defmodule ICalendar.Attachment do
  defstruct mimetype: nil, uri: nil, base64: nil

  @type t :: %__MODULE__{
          mimetype: String.t() | nil,
          uri: String.t() | nil,
          base64: binary() | nil
        }
end
