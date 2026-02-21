defmodule ICal.Serialize.Todo do
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

  defp to_ics({:completed, value}, acc) do
    acc ++ [Serialize.date_to_ics("COMPLETED", value)]
  end

  defp to_ics({:due, value}, acc) do
    acc ++ [Serialize.date_to_ics("DUE", value)]
  end

  defp to_ics({:percent_completed, value}, acc) do
    if value > 0 do
      acc ++ ["PERCENT-COMPLETED:", Serialize.to_ics(value)]
    else
      acc
    end
  end

  ICal.Serialize.Component.trailing_serializers()
end
