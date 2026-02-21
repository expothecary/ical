defmodule ICal.Deserialize.Journal do
  @moduledoc false

  alias ICal.Deserialize
  require ICal.Deserialize.Component

  @spec one(data :: binary, ICal.t()) :: {data :: binary, nil | ICal.Journal.t()}

  Deserialize.Component.rejection_guards()

  def one(data, %ICal{} = calendar) do
    next_parameter(data, calendar, %ICal.Journal{})
  end

  Deserialize.Component.parameter_parsers([])
  Deserialize.Component.trailing_parsers("VJOURNAL")
  Deserialize.Component.helpers()
end
