defmodule ICal.Serialize.Event do
  @moduledoc false

  require ICal.Serialize.Component
  alias ICal.Serialize

  def to_ics(event) do
    contents =
      event
      |> Map.from_struct()
      |> Enum.reduce([], &to_ics/2)

    [
      "BEGIN:VEVENT\n",
      contents,
      "END:VEVENT\n"
    ]
  end

  ICal.Serialize.Component.parameter_serializers()

  defp to_ics({:dtend, value}, acc) do
    acc ++ [Serialize.date_to_ics("DTEND", value)]
  end

  defp to_ics({:transparency, value}, acc) do
    value = if value == :transparent, do: "TRANSPARENT", else: "OPAQUE"

    acc ++ [Serialize.kv_to_ics("TRANSP", value)]
  end

  ICal.Serialize.Component.trailing_serializers()
end
