defmodule ICal.Deserialize.Event do
  @moduledoc false

  alias ICal.Deserialize

  @spec one(data :: binary, ICal.t()) :: {data :: binary, ICal.Event.t()}
  def one(data, calendar) do
    next(data, calendar, %ICal.Event{})
  end

  defp next(<<>> = data, _calendar, event), do: {data, event}

  defp next(<<"ATTACH", data::binary>>, calendar, event) do
    {data, attachment} = Deserialize.attachment(data)
    record_value(data, calendar, event, :attachments, [attachment])
  end

  defp next(<<"ATTENDEE", data::binary>>, calendar, event) do
    {data, attendee} = Deserialize.Attendee.one(data)
    record_value(data, calendar, event, :attendees, [attendee])
  end

  defp next(<<"BEGIN:VALARM", data::binary>>, calendar, event) do
    {data, alarm} = Deserialize.Alarm.one(data, calendar)
    record_value(data, calendar, event, :alarms, [alarm])
  end

  defp next(<<"CATEGORIES", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, values} = Deserialize.comma_separated_list(data)
    record_value(data, calendar, event, :categories, values)
  end

  defp next(<<"CLASS", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)
    record_value(data, calendar, event, :class, value)
  end

  defp next(<<"COMMENT", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.multi_line(data)
    record_value(data, calendar, event, :comments, [value])
  end

  defp next(<<"CONTACT", data::binary>>, calendar, event) do
    {data, contact} = Deserialize.Contact.from_ics(data)
    record_value(data, calendar, event, :contacts, [contact])
  end

  defp next(<<"CREATED", data::binary>>, calendar, event) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)
    record_value(data, calendar, event, :created, Deserialize.to_date(value, params, calendar))
  end

  defp next(<<"DESCRIPTION", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.multi_line(data)
    record_value(data, calendar, event, :description, value)
  end

  defp next(<<"DTSTART", data::binary>>, calendar, event) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)
    record_value(data, calendar, event, :dtstart, Deserialize.to_date(value, params, calendar))
  end

  defp next(<<"DTEND", data::binary>>, calendar, event) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)
    record_value(data, calendar, event, :dtend, Deserialize.to_date(value, params, calendar))
  end

  defp next(<<"DTSTAMP", data::binary>>, calendar, event) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)
    record_value(data, calendar, event, :dtstamp, Deserialize.to_date(value, params, calendar))
  end

  defp next(<<"DURATION", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, duration} = Deserialize.Duration.one(data)
    record_value(data, calendar, event, :duration, duration)
  end

  defp next(<<"EXDATE", data::binary>>, calendar, event) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)
    date = Deserialize.to_date(value, params, calendar)
    record_value(data, calendar, event, :exdates, [date])
  end

  defp next(<<"GEO", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)
    geo = Deserialize.parse_geo(value)
    record_value(data, calendar, event, :geo, geo)
  end

  defp next(<<"LAST-MODIFIED", data::binary>>, calendar, event) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)
    record_value(data, calendar, event, :modified, Deserialize.to_date(value, params, calendar))
  end

  defp next(<<"LOCATION", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)
    record_value(data, calendar, event, :location, value)
  end

  defp next(<<"ORGANIZER", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)
    record_value(data, calendar, event, :organizer, value)
  end

  defp next(<<"PRIORITY", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)

    record_integer_value(data, calendar, event, :priority, value)
  end

  defp next(<<"RECURRENCE-ID", data::binary>>, calendar, event) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)

    record_value(
      data,
      calendar,
      event,
      :recurrence_id,
      Deserialize.to_date(value, params, calendar)
    )
  end

  defp next(<<"RELATED-TO", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)
    record_value(data, calendar, event, :related_to, [value])
  end

  defp next(<<"RESOURCES", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.comma_separated_list(data)
    record_value(data, calendar, event, :resources, value)
  end

  defp next(<<"RDATE", data::binary>>, calendar, event) do
    {data, params} = Deserialize.params(data)
    {data, values} = Deserialize.comma_separated_list(data)
    type = Map.get(params, "VALUE", "DATE")

    rdates =
      values
      |> Enum.reduce([], fn value, acc -> to_rdate(type, params, value, calendar, acc) end)
      |> Enum.reverse()

    record_value(data, calendar, event, :rdates, rdates)
  end

  defp next(<<"RRULE", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, values} = Deserialize.param_list(data)

    rrule = Deserialize.Recurrence.from_params(values)
    record_value(data, calendar, event, :rrule, rrule)
  end

  defp next(<<"SEQUENCE", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)
    record_integer_value(data, calendar, event, :sequence, value)
  end

  defp next(<<"STATUS", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.multi_line(data)
    status = to_status(value)
    record_value(data, calendar, event, :status, status)
  end

  defp next(<<"SUMMARY", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.multi_line(data)
    record_value(data, calendar, event, :summary, value)
  end

  defp next(<<"TRANSP", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.rest_of_line(data)

    case value do
      "OPAQUE" -> next(data, calendar, %{event | transparency: :opaque})
      "TRANSPARENT" -> next(data, calendar, %{event | transparency: :transparent})
      _ -> next(data, calendar, event)
    end
  end

  defp next(<<"UID", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)

    {data, value} = Deserialize.multi_line(data)

    record_value(data, calendar, event, :uid, value)
  end

  defp next(<<"URL", data::binary>>, calendar, event) do
    data = Deserialize.skip_params(data)
    {data, value} = Deserialize.multi_line(data)
    record_value(data, calendar, event, :url, value)
  end

  # prevent losing other non-standard headers
  defp next(<<"X-", data::binary>>, calendar, event) do
    {data, key} = Deserialize.rest_of_key(data, "X-")
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)

    custom_entry = %{params: params, value: value}
    custom_properties = Map.put(event.custom_properties, key, custom_entry)
    next(data, calendar, %{event | custom_properties: custom_properties})
  end

  defp next(<<"END:VEVENT", data::binary>>, _calendar, event) do
    {data, event}
  end

  defp next(data, calendar, event) do
    data
    |> Deserialize.skip_line()
    |> next(calendar, event)
  end

  # a helper that skips empty values, concats lists, then moves to the next
  defp record_value(data, calendar, event, _key, nil), do: next(data, calendar, event)
  defp record_value(data, calendar, event, _key, []), do: next(data, calendar, event)
  defp record_value(data, calendar, event, _key, [nil]), do: next(data, calendar, event)

  defp record_value(data, calendar, event, key, value) when is_list(value) do
    next(data, calendar, Map.put(event, key, Map.get(event, key, []) ++ value))
  end

  defp record_value(data, calendar, event, key, value),
    do: next(data, calendar, Map.put(event, key, value))

  defp record_integer_value(data, calendar, event, key, value) do
    case Deserialize.to_integer(value) do
      nil -> next(data, calendar, event)
      integer -> next(data, calendar, Map.put(event, key, integer))
    end
  end

  defp to_status("TENTATIVE"), do: :tentative
  defp to_status("CONFIRMED"), do: :confirmed
  defp to_status("CANCELLED"), do: :cancelled
  defp to_status(_), do: nil

  defp to_rdate("DATE", params, value, calendar, acc) do
    case Deserialize.to_date(value, params, calendar) do
      nil -> acc
      date -> [date | acc]
    end
  end

  defp to_rdate("PERIOD", params, value, calendar, acc) do
    with [first, second] <- String.split(value, "/", parts: 2),
         p_start when p_start != nil <- Deserialize.to_date(first, params, calendar),
         p_end when p_end != nil <- to_period_end(second, params, calendar) do
      [{p_start, p_end} | acc]
    else
      _ -> acc
    end
  end

  defp to_rdate(_unrecognized, _params, _value, _calendar, acc), do: acc

  defp to_period_end(end_string, params, calendar) do
    date = Deserialize.to_date(end_string, params, calendar)

    if date == nil do
      {_, duration} = Deserialize.Duration.one(end_string)
      duration
    else
      date
    end
  end
end
