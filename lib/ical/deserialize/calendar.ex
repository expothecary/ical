defmodule ICal.Deserialize.Calendar do
  @moduledoc false

  alias ICal.Deserialize

  def from_file(path) do
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
    case ICal.Deserialize.Event.one(data, calendar) do
      {data, nil} ->
        next(data, calendar)

      {data, event} ->
        calendar = %{calendar | events: calendar.events ++ [event]}
        next(data, calendar)
    end
  end

  def next(<<"BEGIN:VTODO", data::binary>>, calendar) do
    case ICal.Deserialize.Todo.one(data, calendar) do
      {data, nil} ->
        next(data, calendar)

      {data, todo} ->
        calendar = %{calendar | todos: calendar.todos ++ [todo]}
        next(data, calendar)
    end
  end

  def next(<<"BEGIN:VTIMEZONE", data::binary>>, calendar) do
    case ICal.Deserialize.Timezone.one(data) do
      {data, nil} ->
        next(data, calendar)

      {data, timezone} ->
        calendar = %{calendar | timezones: Map.put(calendar.timezones, timezone.id, timezone)}
        next(data, calendar)
    end
  end

  def next(<<"BEGIN:VCALENDAR\n", data::binary>>, calendar) do
    next(data, calendar)
  end

  def next(<<"BEGIN:", data::binary>>, calendar) do
    {data, value} = Deserialize.rest_of_line(data)

    {data, component} =
      Deserialize.gather_unrecognized_component(data, "END:#{value}\n", ["BEGIN:#{value}\n"])

    next(data, %{calendar | __other_components: calendar.__other_components ++ [component]})
  end

  def next(<<"PRODID:", data::binary>>, calendar) do
    {data, value} = Deserialize.rest_of_line(data)
    next(data, %{calendar | product_id: value})
  end

  def next(<<"NAME:", data::binary>>, calendar) do
    {data, value} = Deserialize.rest_of_line(data)
    next(data, %{calendar | name: value})
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

    next(
      data,
      %{calendar | default_timezone: tz}
      |> add_custom_entry("X-WR-TIMEZONE", %{}, value)
    )
  end

  # only use X-WR-CALNAME if a name is not already set
  def next(<<"X-WR-CALNAME:", data::binary>>, %{name: nil} = calendar) do
    {data, value} = Deserialize.rest_of_line(data)

    next(
      data,
      %{calendar | name: value} |> add_custom_entry("X-WR-CALNAME", %{}, value)
    )
  end

  # prevent losing other non-standard headers
  def next(<<"X-", data::binary>>, calendar) do
    {data, key} = Deserialize.rest_of_key(data, "X-")
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)

    next(data, calendar |> add_custom_entry(key, params, value))
  end

  def next(<<"END:VCALENDAR", _data::binary>>, calendar) do
    calendar
  end

  def next(data, calendar) do
    next(Deserialize.skip_line(data), calendar)
  end

  defp add_custom_entry(calendar, key, params, value) do
    custom_entry = %{params: params, value: value}
    custom_properties = Map.put(calendar.custom_properties, key, custom_entry)
    %{calendar | custom_properties: custom_properties}
  end
end
