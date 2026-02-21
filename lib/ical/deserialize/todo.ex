defmodule ICal.Deserialize.Todo do
  @moduledoc false

  alias ICal.Deserialize
  require ICal.Deserialize.Component

  @spec one(data :: binary, ICal.t()) :: {data :: binary, ICal.Todo.t()}
  def one(data, calendar) do
    next(data, calendar, %ICal.Todo{})
  end

  Deserialize.Component.parameter_parsers()

  defp next(<<"COMPLETED", data::binary>>, calendar, event) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)
    record_value(data, calendar, event, :completed, Deserialize.to_date(value, params, calendar))
  end

  defp next(<<"DUE", data::binary>>, calendar, event) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)
    record_value(data, calendar, event, :due, Deserialize.to_date(value, params, calendar))
  end

  defp next(<<"PERCENT-COMPLETE", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)
    record_integer_value(data, calendar, event, :percent, value)
  end

  Deserialize.Component.trailing_parsers("VTODO")
  Deserialize.Component.helpers()
end
