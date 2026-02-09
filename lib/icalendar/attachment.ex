defmodule ICalendar.Attachment do
  @enforce_keys [:data_type, :data]
  defstruct [:data_type, :data, mimetype: nil]

  @type t :: %__MODULE__{
          data_type: :uri | :cid | :base8 | :base64,
          data: String.t(),
          mimetype: String.t() | nil
        }
end
