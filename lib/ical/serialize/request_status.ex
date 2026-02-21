defmodule ICal.Serialize.RequestStatus do
  @moduledoc false

  alias ICal.Serialize

  def property(%ICal.RequestStatus{} = request_status) do
    [
      "REQUEST-STATUS",
      params(request_status),
      code(request_status),
      description(request_status),
      exception(request_status),
      ?\n
    ]
  end

  defp params(%ICal.RequestStatus{language: nil}), do: ?:
  defp params(%ICal.RequestStatus{language: language}), do: [";LANGUAGE=", language, ?:]

  defp code(%ICal.RequestStatus{code: {x, y}}), do: "#{x}.#{y}"
  defp code(%ICal.RequestStatus{code: {x, y, z}}), do: "#{x}.#{y}.#{z}"

  defp description(%ICal.RequestStatus{description: nil}), do: ""
  defp description(%ICal.RequestStatus{description: desc}), do: [?;, Serialize.value(desc)]

  defp exception(%ICal.RequestStatus{exception: nil}), do: ""
  defp exception(%ICal.RequestStatus{exception: exception}), do: [?;, Serialize.value(exception)]
end
