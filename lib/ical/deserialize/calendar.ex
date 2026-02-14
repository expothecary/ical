defmodule ICal.Deserialize.Calendar do
  @moduledoc false

  alias ICal.Deserialize

  def from_file(path) do
    # TODO: a streaming parser would be nice!
    with {:ok, data} <- File.read(path),
         %ICal{} = calendar <- from_ics(data) do
      calendar
    else
      error -> error
    end
  end

  def from_ics(data) when is_binary(data) do
    next(data, %ICal{})
  end

  def next(<<>>, calendar), do: calendar
  def next(<<?\n, data::binary>>, calendar), do: next(data, calendar)

  def next(<<"BEGIN:VEVENT", data::binary>>, calendar) do
    ICal.Deserialize.Event.one(data, calendar)
  end

  def next(<<"BEGIN:VCALENDAR\n", data::binary>>, calendar) do
    next(data, calendar)
  end

  def next(<<"PRODID:", data::binary>>, calendar) do
    {data, value} = Deserialize.rest_of_line(data)
    next(data, %{calendar | product_id: value})
  end

  def next(<<"METHOD:", data::binary>>, calendar) do
    {data, value} = Deserialize.rest_of_line(data)
    next(data, %{calendar | method: value})
  end

  def next(<<"CALSCALE:", data::binary>>, calendar) do
    {data, value} = Deserialize.rest_of_line(data)
    next(data, %{calendar | scale: value})
  end

  def next(<<"VERSION:", data::binary>>, calendar) do
    {data, value} = Deserialize.rest_of_line(data)
    next(data, %{calendar | version: value})
  end

  # X-WR-TIMEZONE is a non-standard, but widely used, field
  # that allows setting the default timezone for the whole calendar
  def next(<<"X-WR-TIMEZONE:", data::binary>>, calendar) do
    {data, value} = Deserialize.rest_of_line(data)
    tz = Deserialize.to_timezone(value, calendar.default_timezone)

    custom_entry = %{params: %{}, value: tz}
    custom_entries = Map.put(calendar.custom_entries, "X-WR-TIMEZONE", custom_entry)

    next(data, %{calendar | default_timezone: tz, custom_entries: custom_entries})
  end

  # prevent losing other non-standard headers
  def next(<<"X-", data::binary>>, calendar) do
    {data, key} = Deserialize.rest_of_key(data, "X-")
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)

    custom_entry = %{params: params, value: value}
    custom_entries = Map.put(calendar.custom_entries, key, custom_entry)
    next(data, %{calendar | custom_entries: custom_entries})
  end

  def next(<<"END:VCALENDAR", _data::binary>>, calendar) do
    calendar
  end

  def next(data, calendar) do
    next(Deserialize.skip_line(data), calendar)
  end
end
