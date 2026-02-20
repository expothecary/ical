defmodule ICal.RequestStatus do
  defstruct [:code, :description, :exception, :language]

  @type maybe :: %__MODULE__{}
  @type status_short :: {non_neg_integer(), non_neg_integer()}
  @type status_detailed :: {non_neg_integer(), non_neg_integer(), non_neg_integer}

  @type t :: %__MODULE__{
          code: status_short() | status_detailed(),
          description: String.t(),
          exception: nil | String.t(),
          language: nil | String.t()
        }
end
