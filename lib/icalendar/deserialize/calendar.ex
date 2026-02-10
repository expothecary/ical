defmodule ICalendar.Deserialize.Calendar do
  @moduledoc false

  alias ICalendar.Deserialize

  def from_file(path) do
    # TODO: a streaming parser would be nice!
    with {:ok, data} <- File.read(path),
         %ICalendar{} = calendar <- from_ics(data) do
      calendar
    else
      error -> error
    end
  end

  def from_ics(data) when is_binary(data) do
    next(data, %ICalendar{})
  end

  def next(<<>>, calendar), do: calendar
  def next(<<?\n, data::binary>>, calendar), do: next(data, calendar)

  def next(<<"BEGIN:VEVENT", data::binary>>, calendar) do
    ICalendar.Deserialize.Event.one(data, calendar)
  end

  def next(<<"BEGIN:VCALENDAR\n", data::binary>>, calendar) do
    next(data, calendar)
  end

  def next(<<"PRODID\n", data::binary>>, calendar) do
    {data, value} = Deserialize.rest_of_line(data)
    next(data, %{calendar | product_id: value})
  end

  def next(<<"METHOD\n", data::binary>>, calendar) do
    {data, value} = Deserialize.rest_of_line(data)
    next(data, %{calendar | method: value})
  end

  def next(<<"CALSCALE\n", data::binary>>, calendar) do
    {data, value} = Deserialize.rest_of_line(data)
    next(data, %{calendar | scale: value})
  end

  def next(<<"VERSION\n", data::binary>>, calendar) do
    {data, value} = Deserialize.rest_of_line(data)
    next(data, %{calendar | version: value})
  end

  def next(<<"END:VCALENDAR", _data::binary>>, calendar) do
    calendar
  end

  def next(data, calendar) do
    next(Deserialize.skip_line(data), calendar)
  end
end
