defmodule ICal.Deserialize.Timezone do
  @moduledoc false

  alias ICal.Deserialize

  @type maybe_timezone :: nil | ICal.Timezone.t()
  @spec one(data :: binary()) :: {data :: binary, maybe_timezone}
  def one(data) do
    next(data, %ICal.Timezone{})
  end

  @spec next(data :: binary(), ICal.Timezone.maybe()) ::
          {data :: binary, nil | ICal.Timezone.t()}
  defp next(<<>> = data, _timezone) do
    {data, nil}
  end

  defp next(<<"END:VTIMEZONE\n", data::binary>>, timezone) do
    if timezone.id == nil do
      {data, nil}
    else
      {data, timezone}
    end
  end

  defp next(<<"TZID", data::binary>>, timezone) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)
    timezone = %{timezone | id: value}
    next(data, timezone)
  end

  defp next(<<"TZURL", data::binary>>, timezone) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)
    timezone = %{timezone | url: value}
    next(data, timezone)
  end

  defp next(<<"LAST-MODIFIED", data::binary>>, timezone) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)
    date = Deserialize.to_date_in_timezone(value, "Etc/UTC")
    timezone = %{timezone | last_modified: date}
    next(data, timezone)
  end

  defp next(<<"BEGIN:STANDARD", data::binary>>, timezone) do
    {data, properties} =
      data
      |> Deserialize.skip_line()
      |> next_property(%ICal.Timezone.Properties{})

    if properties != nil do
      next(data, %{timezone | standard: timezone.standard ++ [properties]})
    else
      next(data, timezone)
    end
  end

  defp next(<<"BEGIN:DAYLIGHT", data::binary>>, timezone) do
    {data, properties} =
      data
      |> Deserialize.skip_line()
      |> next_property(%ICal.Timezone.Properties{})

    if properties != nil do
      next(data, %{timezone | daylight: timezone.daylight ++ [properties]})
    else
      next(data, timezone)
    end
  end

  # prevent losing other non-standard headers
  defp next(<<"X-", data::binary>>, timezone) do
    {data, key} = Deserialize.rest_of_key(data, "X-")
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)

    custom_entry = %{params: params, value: value}
    custom_properties = Map.put(timezone.custom_properties, key, custom_entry)
    next(data, %{timezone | custom_properties: custom_properties})
  end

  defp next(data, timezone) do
    data
    |> Deserialize.skip_line()
    |> next(timezone)
  end

  @spec next_property(data :: binary(), ICal.Timezone.Properties.maybe()) ::
          {data :: binary, nil | ICal.Timezone.Properties.t()}
  defp next_property(<<>> = data, _properties) do
    {data, nil}
  end

  defp next_property(<<"END:", data::binary>>, properties) do
    # this is a wee bit cheeky: technically it should be checking for
    # "END:#{type}" but that is slower and should never occur in well-formed
    # data
    data = Deserialize.skip_line(data)

    if properties.dtstart != nil do
      {data, properties}
    else
      {data, nil}
    end
  end

  defp next_property(<<"DTSTART", data::binary>>, properties) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)
    date = Deserialize.to_local_date(value)
    properties = %{properties | dtstart: date}
    next_property(data, properties)
  end

  defp next_property(<<"RRULE", data::binary>>, properties) do
    data = Deserialize.skip_params(data)
    {data, params} = Deserialize.param_list(data)
    rule = Deserialize.Recurrence.from_params(params)
    properties = %{properties | rrule: rule}
    next_property(data, properties)
  end

  defp next_property(<<"TZNAME", data::binary>>, properties) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)
    properties = %{properties | names: properties.names ++ [value]}
    next_property(data, properties)
  end

  defp next_property(<<"TZOFFSETFROM", data::binary>>, properties) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)

    properties =
      case Deserialize.to_integer(value) do
        nil -> properties
        offset -> %{properties | offsets: %{properties.offsets | from: offset}}
      end

    next_property(data, properties)
  end

  defp next_property(<<"TZOFFSETTO", data::binary>>, properties) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)

    properties =
      case Deserialize.to_integer(value) do
        nil -> properties
        offset -> %{properties | offsets: %{properties.offsets | to: offset}}
      end

    next_property(data, properties)
  end

  defp next_property(<<"COMMENT", data::binary>>, properties) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)
    properties = %{properties | comments: properties.comments ++ [value]}
    next_property(data, properties)
  end

  defp next_property(<<"RDATE", data::binary>>, properties) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)
    date = Deserialize.to_local_date(value)
    properties = %{properties | rdates: properties.rdates ++ [date]}
    next_property(data, properties)
  end

  # prevent losing other non-standard headers
  defp next_property(<<"X-", data::binary>>, properties) do
    {data, key} = Deserialize.rest_of_key(data, "X-")
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)

    custom_entry = %{params: params, value: value}
    custom_properties = Map.put(properties.custom_properties, key, custom_entry)
    next_property(data, %{properties | custom_properties: custom_properties})
  end

  defp next_property(data, properties) do
    data
    |> Deserialize.skip_line()
    |> next_property(properties)
  end
end
