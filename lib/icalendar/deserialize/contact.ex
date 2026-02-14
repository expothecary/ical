defmodule ICalendar.Deserialize.Contact do
  alias ICalendar.Contact
  alias ICalendar.Deserialize

  def from_ics(data) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.multi_line(data)

    case value do
      "" ->
        {data, nil}

      value ->
        contact = %Contact{
          value: value,
          alternative_representation: Map.get(params, "ALTREP"),
          language: Map.get(params, "LANGUAGE")
        }

        {data, contact}
    end
  end
end
