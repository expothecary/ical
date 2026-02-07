defmodule ICalendar.Deserialize.Event do
  @moduledoc false

  alias ICalendar.Deserialize.Common

  @spec one(data :: binary, ICalendar.t()) :: ICalendar.t()
  def one(data, calendar) do
    {data, event} = next(data, %ICalendar.Event{})
    calendar = %{calendar | events: [event | calendar.events]}
    ICalendar.Deserialize.Calendar.next(data, calendar)
  end

  defp next(<<>> = data, event), do: {data, event}

  defp next(<<"ATTENDEE", data::binary>>, event) do
    {data, params} = Common.params(data)
    {data, value} = Common.rest_of_line(data)
    # FIXME parse out the attendee parameters into an ICalendar.Attendee struct
    next(
      data,
      %{event | attendees: event.attendees ++ [Map.put(params, :original_value, value)]}
    )
  end

  defp next(<<"COMMENT", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.multi_line(data)
    next(data, %{event | comment: value})
  end

  defp next(<<"CATEGORIES", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.comma_separated_list(data)
    next(data, %{event | categories: value})
  end

  defp next(<<"CLASS", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.rest_of_line(data)
    next(data, %{event | class: value})
  end

  defp next(<<"DESCRIPTION", data::binary>>, event) do
    data = Common.skip_params(data)
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

  defp next(<<"EXDATE", data::binary>>, event) do
    {data, params} = Common.params(data)
    {data, value} = Common.rest_of_line(data)

    case Common.to_date(value, params) do
      nil -> next(data, event)
      date -> next(data, %{event | exdates: [date | event.exdates]})
    end
  end

  defp next(<<"GEO", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.rest_of_line(data)
    geo = Common.parse_geo(value)
    next(data, %{event | geo: geo})
  end

  defp next(<<"LAST-MODIFIED", data::binary>>, event) do
    {data, params} = Common.params(data)
    {data, value} = Common.rest_of_line(data)
    next(data, %{event | modified: Common.to_date(value, params)})
  end

  defp next(<<"LOCATION", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.rest_of_line(data)
    next(data, %{event | location: value})
  end

  defp next(<<"ORGANIZER", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.rest_of_line(data)
    next(data, %{event | organizer: value})
  end

  defp next(<<"RECURRENCE-ID", data::binary>>, event) do
    {data, params} = Common.params(data)
    {data, value} = Common.rest_of_line(data)
    # TODO parse recurrence rules
    next(data, %{event | recurrence_id: Common.to_date(value, params)})
  end

  # TODO: RDATE -> https://datatracker.ietf.org/doc/html/rfc5545#section-3.8.5.2

  defp next(<<"RRULE", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, values} = Common.params(data)

    # FIXME: this should really be a Recurrence struct, and it this parsing should be
    rrule =
      Enum.reduce(values, %{}, &to_rrule/2)

    next(data, %{event | rrule: rrule})
  end

  defp next(<<"SEQUENCE", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.rest_of_line(data)
    next(data, %{event | sequence: value})
  end

  defp next(<<"SUMMARY", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.multi_line(data)
    next(data, %{event | summary: value})
  end

  defp next(<<"STATUS", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.multi_line(data)
    status = to_status(value)
    next(data, %{event | status: status})
  end

  defp next(<<"UID", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.rest_of_line(data)
    next(data, %{event | uid: value})
  end

  defp next(<<"URL", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.rest_of_line(data)
    next(data, %{event | url: value})
  end

  defp next(<<"END:VEVENT", data::binary>>, event) do
    {data, event}
  end

  defp next(data, event) do
    data
    |> Common.skip_line()
    |> next(event)
  end

  defp to_status("TENTATIVE"), do: :tentative
  defp to_status("CONFIRMED"), do: :confirmed
  defp to_status("CANCELLED"), do: :cancelled
  defp to_status(_), do: nil

  # TODO: move to another module?
  defp to_rrule({str_key, raw_value}, acc) do
    try do
      key =
        str_key
        |> String.downcase()
        |> String.to_existing_atom()

      value = rrule_value(key, raw_value)

      Map.put(acc, key, value)
    rescue
      # due to atom not existing or a value parsing incorrectly
      _ -> acc
    end
  end

  defp rrule_value(key, value)
       when key == :freq or
              key == :wkst do
    value
  end

  defp rrule_value(key, value) when key == :until do
    ICalendar.Util.DateParser.parse(value)
  end

  defp rrule_value(key, value)
       when key == :count or
              key == :interval do
    String.to_integer(value)
  end

  defp rrule_value(key, value)
       when key == :bysecond or
              key == :byminute or
              key == :byhour or
              key == :bymonthday or
              key == :byday or
              key == :byyearday or
              key == :byweekno or
              key == :bymonth do
    String.split(value, ",")
  end

  defp rrule_value(:bysetpos, value) do
    value
    |> String.split(",")
    |> Enum.map(&String.to_integer(&1))
  end

  defp rrule_value(_key, value), do: value
end
