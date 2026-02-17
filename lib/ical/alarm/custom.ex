defmodule ICal.Alarm.Custom do
  @moduledoc "A custom alarm with properties"

  defstruct [:type, properties: %{}]

  @type t :: %__MODULE__{
          type: String.t(),
          properties: %{(key :: String.t()) => %{params: map, value: term}}
        }
end
