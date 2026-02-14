defmodule ICalendar.Serialize.Contact do
  alias ICalendar.Contact
  alias ICalendar.Serialize

  def to_ics(%Contact{} = contact) do
    params = [] |> add_alt(contact) |> add_language(contact)
    ["CONTACT", params, ?:, Serialize.to_ics(contact.value), ?\n]
  end

  defp add_alt(params, %Contact{alternative_representation: nil}), do: params

  defp add_alt(params, %Contact{alternative_representation: alt}),
    do: [";ALTREP=", Serialize.to_quoted_value(alt) | params]

  defp add_language(params, %Contact{language: nil}), do: params
  defp add_language(params, %Contact{language: language}), do: [";LANGAUGE=", language | params]
end
