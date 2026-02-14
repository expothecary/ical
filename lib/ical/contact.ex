defmodule ICal.Contact do
  @enforce_keys :value

  # TODO: should alternative_representation be parsed further for CID, URI, ..?
  defstruct [:value, alternative_representation: nil, language: nil]

  @type t :: %__MODULE__{
          value: String.t(),
          alternative_representation: String.t() | nil,
          language: String.t() | nil
        }
end
