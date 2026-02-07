defmodule ICalendar.Deserialize.Event do
  @moduledoc false

  alias ICalendar.Deserialize.Common

  @spec one(data :: binary, ICalendar.t()) :: ICalendar.t()
  def one(data, calendar) do
    {data, event} = next(data, %ICalendar.Event{})
    calendar = %{calendar | events: [event | calendar.events]}
    ICalendar.Deserialize.Calendar.next(data, calendar)
  end

  defp next(<<>>, event), do: event

  defp next(<<"COMMENT", data::binary>>, event) do
    {data, _params} = Common.params(data)
    {data, value} = Common.multi_line(data)
    next(data, %{event | comment: value})
  end

  defp next(<<"DESCRIPTION", data::binary>>, event) do
    {data, _params} = Common.params(data)
    {data, value} = Common.multi_line(data)
    next(data, %{event | description: value})
  end

  defp next(<<"DTSTART", data::binary>>, event) do
    {data, params} = Common.params(data)
    {data, value} = Common.rest_of_line(data)
    next(data, %{event | dtstart: Common.to_date(value, params)})
  end

  defp next(<<"DTEND", data::binary>>, event) do
    {data, params} = Common.params(data)
    {data, value} = Common.rest_of_line(data)
    next(data, %{event | dtend: Common.to_date(value, params)})
  end

  defp next(<<"DTSTAMP", data::binary>>, event) do
    {data, params} = Common.params(data)
    {data, value} = Common.rest_of_line(data)
    next(data, %{event | dtstamp: Common.to_date(value, params)})
  end

  defp next(<<"RECURRENCE-ID", data::binary>>, event) do
    {data, params} = Common.params(data)
    {data, value} = Common.rest_of_line(data)
    # TODO parse recurrence rules
    next(data, %{event | recurrence_id: Common.to_date(value, params)})
  end

  defp next(<<"RRULE", data::binary>>, event) do
    {data, _params} = Common.params(data)
    {data, value} = Common.rest_of_line(data)
    next(data, %{event | rrule: value})
  end

  defp next(<<"SUMMARY", data::binary>>, event) do
    {data, _params} = Common.params(data)
    {data, value} = Common.multi_line(data)
    next(data, %{event | summary: value})
  end

  defp next(<<"UID", data::binary>>, event) do
    {data, _params} = Common.params(data)
    {data, value} = Common.rest_of_line(data)
    next(data, %{event | uid: value})
  end

  defp next(<<"URL", data::binary>>, event) do
    {data, _params} = Common.params(data)
    {data, value} = Common.rest_of_line(data)
    next(data, %{event | url: value})
  end

  defp next(<<"END:VEVENT", data::binary>>, event) do
    {data, event}
  end

  defp next(data, event) do
    data
    |> Common.consume_line()
    |> next(event)
  end
end
