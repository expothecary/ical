defmodule ICal.Serialize.Availability do
  @moduledoc false

  require ICal.Serialize.Component
  alias ICal.Serialize

  def component(availability) do
    contents =
      availability
      |> Map.from_struct()
      |> Enum.reduce([], &serialize/2)

    [
      "BEGIN:VAVAILABILITY\n",
      contents,
      "END:VAVAILABILITY\n"
    ]
  end

  ICal.Serialize.Component.parameter_serializers()

  defp serialize({:dtend, value}, acc) do
    acc ++ [Serialize.date("DTEND", value)]
  end

  defp serialize({:busytype, value}, acc) do
    acc ++ [Serialize.kv("BUSYTYPE", busytype(value))]
  end

  defp serialize({:available, available}, acc) do
    acc ++ Enum.map(available, &ICal.Serialize.Availability.Available.component/1)
  end

  defp busytype(:busy), do: "BUSY"
  defp busytype(:busy_unavailable), do: "BUSY-UNAVAILABLE"
  defp busytype(:busy_tentative), do: "BUSY-TENTATIVE"
  defp busytype(token) when is_binary(token), do: token

  ICal.Serialize.Component.trailing_serializers()
end
