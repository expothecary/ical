defmodule ICal.Serialize.Journal do
  @moduledoc false

  require ICal.Serialize.Component

  def component(%ICal.Journal{} = journal) do
    contents =
      journal
      |> Map.from_struct()
      |> Enum.reduce([], &serialize/2)

    [
      "BEGIN:VJOURNAL\n",
      contents,
      "END:VJOURNAL\n"
    ]
  end

  ICal.Serialize.Component.parameter_serializers()
  ICal.Serialize.Component.trailing_serializers()
end
