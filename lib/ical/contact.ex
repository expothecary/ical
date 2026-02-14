defmodule ICal.Contact do
  @moduledoc """
  An iCalendar Contact.
  """

  @enforce_keys :value

  @type t :: %__MODULE__{
          value: String.t(),
          alternative_representation: String.t() | nil,
          language: String.t() | nil
        }
end
