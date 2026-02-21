defmodule ICal.Serialize.Todo do
  @moduledoc false

  require ICal.Serialize.Component
  alias ICal.Serialize

  def component(event) do
    contents =
      event
      |> Map.from_struct()
      |> Enum.reduce([], &serialize/2)

    [
      "BEGIN:VTODO\n",
      contents,
      "END:VTODO\n"
    ]
  end

  ICal.Serialize.Component.parameter_serializers()

  defp serialize({:completed, value}, acc) do
    acc ++ Serialize.date("COMPLETED", value)
  end

  defp serialize({:due, value}, acc) do
    acc ++ Serialize.date("DUE", value)
  end

  defp serialize({:percent_completed, value}, acc) do
    if value > 0 do
      acc ++ ["PERCENT-COMPLETE:", Serialize.value(value), ?\n]
    else
      acc
    end
  end

  ICal.Serialize.Component.trailing_serializers()
end
