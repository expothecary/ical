defmodule ICal.Attachment do
  @moduledoc """
  An ICal attachment entry. CID, URI, and binary attachments are supported.
  """

  @enforce_keys [:data_type, :data]
  defstruct [:data_type, :data, mimetype: nil]

  @type t :: %__MODULE__{
          data_type: :uri | :cid | :base8 | :base64,
          data: String.t(),
          mimetype: String.t() | nil
        }

  @spec decoded_data(t()) :: String.t() | binary
  @doc """
  Returns the decoded data for an Attachment.

  For CID and URI attachments, this is simply the string representing the resource.

  For inline binary attachments, this is decoded based on its advertised encoding.
  """
  def decoded_data(%__MODULE__{data_type: :base64, data: data}) do
    case Base.decode64(data) do
      :error -> Base.decode64(data, padding: false)
      decoded -> decoded
    end
  end

  def decoded_data(%__MODULE__{data: data}), do: {:ok, data}
end
