defmodule ICalendar.Attachment do
  @enforce_keys [:data_type, :data]
  defstruct [:data_type, :data, mimetype: nil]

  @type t :: %__MODULE__{
          data_type: :uri | :cid | :base8 | :base64,
          data: String.t(),
          mimetype: String.t() | nil
        }

  def decoded_data(%__MODULE__{data_type: :base64, data: data}) do
    case Base.decode64(data) do
      :error -> Base.decode64(data, padding: false)
      decoded -> decoded
    end
  end

  def decoded_data(%__MODULE__{data: data}), do: data
end
