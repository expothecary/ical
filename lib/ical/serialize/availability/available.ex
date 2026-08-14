defmodule ICal.Serialize.Availability.Available do
  @moduledoc false

  require ICal.Serialize.Component
  alias ICal.Serialize

  def component(available) do
    contents =
      available
      |> Map.from_struct()
      |> Enum.reduce([], &serialize/2)

    [
      "BEGIN:AVAILABLE\n",
      contents,
      "END:AVAILABLE\n"
    ]
  end

  ICal.Serialize.Component.parameter_serializers()

  defp serialize({:dtend, value}, acc) do
    acc ++ [Serialize.date("DTEND", value)]
  end

  ICal.Serialize.Component.trailing_serializers()
end
