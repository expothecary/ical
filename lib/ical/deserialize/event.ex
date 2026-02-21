defmodule ICal.Deserialize.Event do
  @moduledoc false

  alias ICal.Deserialize
  require ICal.Deserialize.Component

  @spec one(data :: binary, ICal.t()) :: {data :: binary, ICal.Event.t()}
  def one(data, calendar) do
    next_parameter(data, calendar, %ICal.Event{})
  end

  Deserialize.Component.parameter_parsers()

  defp next_parameter(<<"DTEND", data::binary>>, calendar, event) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)
    record_value(data, calendar, event, :dtend, Deserialize.to_date(value, params, calendar))
  end

  defp next_parameter(<<"TRANSP", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)

    case value do
      "OPAQUE" -> next_parameter(data, calendar, %{event | transparency: :opaque})
      "TRANSPARENT" -> next_parameter(data, calendar, %{event | transparency: :transparent})
      _ -> next_parameter(data, calendar, event)
    end
  end

  Deserialize.Component.trailing_parsers("VEVENT")
  Deserialize.Component.helpers()
end
