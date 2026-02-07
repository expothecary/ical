defmodule ICalendar.Deserialize.Calendar do
  @moduledoc false

  alias ICalendar.Deserialize.Common

  def one(data) when is_binary(data) do
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
    {data, value} = Common.rest_of_line(data)
    next(data, %{calendar | product_id: value})
  end

  def next(<<"VERSION\n", data::binary>>, calendar) do
    {data, value} = Common.rest_of_line(data)
    next(data, %{calendar | version: value})
  end

  def next(<<"END:VCALENDAR", _data::binary>>, calendar) do
    calendar
  end
end
