defmodule ICal.Deserialize.Contact do
  @moduledoc false

  alias ICal.Contact
  alias ICal.Deserialize

  def from_ics(data) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.value(data)

    case value do
      nil ->
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
