defmodule ICal.Deserialize.Todo do
  @moduledoc false

  alias ICal.Deserialize
  require ICal.Deserialize.Component

  @spec one(data :: binary, ICal.t()) :: {data :: binary, nil | ICal.Todo.t()}

  Deserialize.Component.rejection_guards()

  def one(data, calendar) do
    next_parameter(data, calendar, %ICal.Todo{})
  end

  Deserialize.Component.parameter_parsers()

  defp next_parameter(<<"COMPLETED", data::binary>>, calendar, event) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)
    record_value(data, calendar, event, :completed, Deserialize.to_date(value, params, calendar))
  end

  defp next_parameter(<<"DUE", data::binary>>, calendar, event) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)
    record_value(data, calendar, event, :due, Deserialize.to_date(value, params, calendar))
  end

  defp next_parameter(<<"PERCENT-COMPLETE", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)
    record_integer_value(data, calendar, event, :percent_completed, value)
  end

  Deserialize.Component.trailing_parsers("VTODO")
  Deserialize.Component.helpers()
end
