defmodule ICal.Deserialize.Event do
  @moduledoc false

  alias ICal.Deserialize
  require ICal.Deserialize.Component

  @spec one(data :: binary, ICal.t()) :: {data :: binary, ICal.Event.t()}
  def one(data, calendar) do
    next(data, calendar, %ICal.Event{})
  end

  Deserialize.Component.parameter_parsers()

  defp next(<<"DTEND", data::binary>>, calendar, event) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)
    record_value(data, calendar, event, :dtend, Deserialize.to_date(value, params, calendar))
  end

  defp next(<<"TRANSP", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)

    case value do
      "OPAQUE" -> next(data, calendar, %{event | transparency: :opaque})
      "TRANSPARENT" -> next(data, calendar, %{event | transparency: :transparent})
      _ -> next(data, calendar, event)
    end
  end

  Deserialize.Component.trailing_parsers("VEVENT")
  Deserialize.Component.helpers()
end
