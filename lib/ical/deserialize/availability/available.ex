
defmodule ICal.Deserialize.Availability.Available do
  @moduledoc false

  alias ICal.Deserialize
  require ICal.Deserialize.Component

  @spec one(data :: binary, ICal.t()) ::
          {data :: binary, nil | ICal.Availability.Available.t()}

  Deserialize.Component.rejection_guards()

  def one(data, calendar) do
    next_parameter(data, calendar, %ICal.Availability.Available{})
  end

  # RFC 7953 allows LOCATION on AVAILABLE but not GEO or RESOURCES.
  Deserialize.Component.parameter_parsers([:location])

  defp next_parameter(<<"DTEND", data::binary>>, calendar, available) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.value(data)

    record_value(data, calendar, available, :dtend, Deserialize.to_date(value, params, calendar))
  end

  Deserialize.Component.trailing_parsers("AVAILABLE")
  Deserialize.Component.helpers()
end
