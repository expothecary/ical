defmodule ICal.Deserialize.Timezone do
  @moduledoc false

  alias ICal.Deserialize

  @spec one(data :: binary, ICal.t()) :: {data :: binary, ICal.Timezone.t()}
  def one(data, calendar) do
    next(data, calendar, %ICal.Timezone{})
  end

  @spec next_property(data :: binary(), calendar :: ICal.t(), ICal.Timezone.t()) ::
          {data :: binary, ICal.Timezone.t()}
  defp next(<<>> = data, _calendar, timezone) do
    {data, timezone}
  end

  defp next(<<"END:VTIMEZONE\n", data::binary>>, _calendar, timezone) do
    {data, timezone}
  end

  defp next(<<"TZID", data::binary>>, calendar, timezone) do
    next(data, calendar, timezone)
  end

  defp next(<<"LAST-MODIFIED", data::binary>>, calendar, timezone) do
    next(data, calendar, timezone)
  end

  defp next(<<"BEGIN:STANDARD", data::binary>>, calendar, timezone) do
    {data, properties} =
      data
      |> Deserialize.skip_line()
      |> next_property(calendar, %ICal.Timezone.Properties{})

    next(data, calendar, %{timezone | standard: properties})
  end

  defp next(<<"BEGIN:DAYLIGHT", data::binary>>, calendar, timezone) do
    {data, properties} =
      data
      |> Deserialize.skip_line()
      |> next_property(calendar, %ICal.Timezone.Properties{})

    next(data, calendar, %{timezone | daylight: properties})
  end

  defp next(<<"COMMENT", data::binary>>, calendar, timezone) do
    next(data, calendar, timezone)
  end

  defp next(<<"RDATE", data::binary>>, calendar, timezone) do
    next(data, calendar, timezone)
  end

  defp next(<<"TZNAME", data::binary>>, calendar, timezone) do
    next(data, calendar, timezone)
  end

  # prevent losing other non-standard headers
  defp next(<<"X-", data::binary>>, calendar, timezone) do
    {data, key} = Deserialize.rest_of_key(data, "X-")
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)

    custom_entry = %{params: params, value: value}
    custom_properties = Map.put(timezone.custom_properties, key, custom_entry)
    next(data, calendar, %{timezone | custom_properties: custom_properties})
  end

  defp next(data, calendar, timezone) do
    data
    |> Deserialize.skip_line()
    |> next(calendar, timezone)
  end

  @spec next_property(data :: binary(), calendar :: ICal.t(), ICal.Timezone.Properties.t()) ::
          {data :: binary, ICal.Timezone.Properties.t()}
  defp next_property(<<"END:", data::binary>>, _calendar, properties) do
    {Deserialize.skip_line(data), properties}
  end

  defp next_property(<<"DTSTART", data::binary>>, calendar, properties) do
    next_property(data, calendar, properties)
  end

  defp next_property(<<"RRULE", data::binary>>, calendar, properties) do
    next_property(data, calendar, properties)
  end

  defp next_property(<<"TZNAME", data::binary>>, calendar, properties) do
    next_property(data, calendar, properties)
  end

  defp next_property(<<"TZOFFSETFROM", data::binary>>, calendar, properties) do
    next_property(data, calendar, properties)
  end

  defp next_property(<<"TZOFFSETTO", data::binary>>, calendar, properties) do
    next_property(data, calendar, properties)
  end

  defp next_property(<<"COMMENT", data::binary>>, calendar, properties) do
    next_property(data, calendar, properties)
  end

  defp next_property(<<"RDATE", data::binary>>, calendar, properties) do
    next_property(data, calendar, properties)
  end

  # prevent losing other non-standard headers
  defp next_property(<<"X-", data::binary>>, calendar, properties) do
    {data, key} = Deserialize.rest_of_key(data, "X-")
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)

    custom_entry = %{params: params, value: value}
    custom_properties = Map.put(properties.custom_properties, key, custom_entry)
    next_property(data, calendar, %{properties | custom_properties: custom_properties})
  end
end
