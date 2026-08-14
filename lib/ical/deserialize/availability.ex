defmodule ICal.Deserialize.Availability do
  @moduledoc false

  alias ICal.Deserialize
  require ICal.Deserialize.Component

  @spec one(data :: binary, ICal.t()) :: {data :: binary, nil | ICal.Availability.t()}

  Deserialize.Component.rejection_guards()

  def one(data, calendar) do
    next_parameter(data, calendar, %ICal.Availability{})
  end

  # RFC 7953 allows LOCATION on VAVAILABILITY but not GEO or RESOURCES.
  Deserialize.Component.parameter_parsers([:location])

  # An AVAILABLE subcomponent is only legal inside VAVAILABILITY, so it is
  # matched here rather than among the shared property parsers.
  defp next_parameter(<<"BEGIN:AVAILABLE", data::binary>>, calendar, availability) do
    {data, available} = ICal.Deserialize.Availability.Available.one(data, calendar)
    record_value(data, calendar, availability, :available, available)
  end

  defp next_parameter(<<"BUSYTYPE", data::binary>>, calendar, availability) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.value(data)

    next_parameter(data, calendar, %{availability | busytype: busytype(value)})
  end

  defp next_parameter(<<"DTEND", data::binary>>, calendar, availability) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.value(data)

    record_value(
      data,
      calendar,
      availability,
      :dtend,
      Deserialize.to_date(value, params, calendar)
    )
  end

  # RFC 7953 §3.1 defines three values; IANA and vendor tokens are kept
  # verbatim so a consumer can still recognise what it knows about.
  defp busytype("BUSY"), do: :busy
  defp busytype("BUSY-UNAVAILABLE"), do: :busy_unavailable
  defp busytype("BUSY-TENTATIVE"), do: :busy_tentative
  defp busytype(token) when is_binary(token), do: token

  Deserialize.Component.trailing_parsers("VAVAILABILITY")
  Deserialize.Component.helpers()
end
