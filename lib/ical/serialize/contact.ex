defmodule ICal.Serialize.Contact do
  @moduledoc false

  alias ICal.Contact
  alias ICal.Serialize

  def property(%Contact{} = contact) do
    params = [] |> add_alt(contact) |> add_language(contact)
    ["CONTACT", params, ?:, Serialize.value(contact.value), ?\n]
  end

  defp add_alt(params, %Contact{alternative_representation: nil}), do: params

  defp add_alt(params, %Contact{alternative_representation: alt}),
    do: [";ALTREP=", Serialize.to_quoted_value(alt) | params]

  defp add_language(params, %Contact{language: nil}), do: params
  defp add_language(params, %Contact{language: language}), do: [";LANGAUGE=", language | params]
end
