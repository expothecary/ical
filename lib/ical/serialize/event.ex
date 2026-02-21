defmodule ICal.Serialize.Event do
  @moduledoc false

  require ICal.Serialize.Component
  alias ICal.Serialize

  def component(event) do
    contents =
      event
      |> Map.from_struct()
      |> Enum.reduce([], &serialize/2)

    [
      "BEGIN:VEVENT\n",
      contents,
      "END:VEVENT\n"
    ]
  end

  ICal.Serialize.Component.parameter_serializers()

  defp serialize({:dtend, value}, acc) do
    acc ++ [Serialize.date("DTEND", value)]
  end

  defp serialize({:transparency, value}, acc) do
    value = if value == :transparent, do: "TRANSPARENT", else: "OPAQUE"
    acc ++ [Serialize.kv("TRANSP", value)]
  end

  ICal.Serialize.Component.trailing_serializers()
end
