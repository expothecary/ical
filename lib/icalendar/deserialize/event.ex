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

  defp next(<<"ATTACH", data::binary>>, event) do
    {data, params} = Common.params(data)
    {data, value} = Common.multi_line(data, "")

    attachment =
      case params do
        %{"ENCODING" => "BASE64", "VALUE" => "BINARY"} ->
          %ICalendar.Attachment{data_type: :base64, data: value}

        %{"ENCODING" => "8BIT", "VALUE" => "BINARY"} ->
          %ICalendar.Attachment{data_type: :base8, data: value}

        _params ->
          case value do
            <<"CID:", cid::binary>> -> %ICalendar.Attachment{data_type: :cid, data: cid}
            value -> %ICalendar.Attachment{data_type: :uri, data: value}
          end
      end
      |> Map.put(:mimetype, Map.get(params, "FMTTYPE"))

    next(
      data,
      %{event | attachments: event.attachments ++ [attachment]}
    )
  end

  defp next(<<"ATTENDEE", data::binary>>, event) do
    {data, params} = Common.params(data)
    {data, value} = Common.rest_of_line(data)
    # FIXME parse out the attendee parameters into an ICalendar.Attendee struct
    next(
      data,
      %{event | attendees: event.attendees ++ [Map.put(params, :original_value, value)]}
    )
  end

  defp next(<<"CATEGORIES", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.comma_separated_list(data)
    next(data, %{event | categories: event.categories ++ value})
  end

  defp next(<<"CLASS", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.rest_of_line(data)
    next(data, %{event | class: value})
  end

  defp next(<<"COMMENT", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.multi_line(data)
    next(data, %{event | comments: [value | event.comments]})
  end

  defp next(<<"CONTACT", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.multi_line(data)
    next(data, %{event | contacts: event.contacts ++ [value]})
  end

  defp next(<<"CREATED", data::binary>>, event) do
    {data, params} = Common.params(data)
    {data, value} = Common.multi_line(data)
    next(data, %{event | created: Common.to_date(value, params)})
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

  defp next(<<"DURATION", data::binary>>, event) do
    {data, _params} = Common.params(data)
    {data, value} = Common.rest_of_line(data)
    # TODO: a duration parser, and a duration struct
    # see https://datatracker.ietf.org/doc/html/rfc5545#section-3.3.6
    next(data, %{event | duration: value})
  end

  defp next(<<"EXDATE", data::binary>>, event) do
    {data, params} = Common.params(data)
    {data, value} = Common.rest_of_line(data)

    case Common.to_date(value, params) do
      nil -> next(data, event)
      date -> next(data, %{event | exdates: event.exdates ++ [date]})
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

  defp next(<<"PRIORITY", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.rest_of_line(data)

    case Integer.parse(value) do
      {priority, ""} -> next(data, %{event | priority: priority})
      _ -> next(data, event)
    end
  end

  defp next(<<"RECURRENCE-ID", data::binary>>, event) do
    {data, params} = Common.params(data)
    {data, value} = Common.rest_of_line(data)
    next(data, %{event | recurrence_id: Common.to_date(value, params)})
  end

  defp next(<<"RELATED-TO", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.rest_of_line(data)
    next(data, %{event | related_to: event.related_to ++ [value]})
  end

  defp next(<<"RESOURCES", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.comma_separated_list(data)
    next(data, %{event | resources: value})
  end

  defp next(<<"RDATE", data::binary>>, event) do
    {data, params} = Common.params(data)
    {data, value} = Common.rest_of_line(data)

    case Common.to_date(value, params) do
      nil ->
        next(data, event)

      date ->
        next(data, %{event | rdates: event.rdates ++ [date]})
    end
  end

  defp next(<<"RRULE", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, values} = Common.params(data)

    # FIXME: this should really be a Recurrence struct
    rrule = Enum.reduce(values, %{}, &to_rrule/2)

    next(data, %{event | rrule: rrule})
  end

  defp next(<<"SEQUENCE", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.rest_of_line(data)
    next(data, %{event | sequence: value})
  end

  defp next(<<"STATUS", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.multi_line(data)
    status = to_status(value)
    next(data, %{event | status: status})
  end

  defp next(<<"SUMMARY", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.multi_line(data)
    next(data, %{event | summary: value})
  end

  defp next(<<"TRANSP", data::binary>>, event) do
    data = Common.skip_params(data)
    {data, value} = Common.rest_of_line(data)

    case value do
      "OPAQUE" -> next(data, %{event | transparency: :opaque})
      "TRANSPARENT" -> next(data, %{event | transparency: :transparent})
      _ -> next(data, event)
    end
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
