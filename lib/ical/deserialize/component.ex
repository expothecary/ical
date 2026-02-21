defmodule ICal.Deserialize.Component do
  @moduledoc false

  defmacro parameter_parsers do
    quote do
      defp next(<<>> = data, _calendar, component), do: {data, component}

      defp next(<<"ATTACH", data::binary>>, calendar, component) do
        {data, attachment} = ICal.Deserialize.attachment(data)
        record_value(data, calendar, component, :attachments, [attachment])
      end

      defp next(<<"ATTENDEE", data::binary>>, calendar, component) do
        {data, attendee} = ICal.Deserialize.Attendee.one(data)
        record_value(data, calendar, component, :attendees, [attendee])
      end

      defp next(<<"BEGIN:VALARM", data::binary>>, calendar, component) do
        {data, alarm} = ICal.Deserialize.Alarm.one(data, calendar)
        record_value(data, calendar, component, :alarms, [alarm])
      end

      defp next(<<"CATEGORIES", data::binary>>, calendar, component) do
        data = ICal.Deserialize.skip_params(data)
        {data, values} = ICal.Deserialize.comma_separated_list(data)
        record_value(data, calendar, component, :categories, values)
      end

      defp next(<<"CLASS", data::binary>>, calendar, component) do
        data = ICal.Deserialize.skip_params(data)
        {data, value} = ICal.Deserialize.rest_of_line(data)
        record_value(data, calendar, component, :class, value)
      end

      defp next(<<"COMMENT", data::binary>>, calendar, component) do
        data = ICal.Deserialize.skip_params(data)
        {data, value} = ICal.Deserialize.multi_line(data)
        record_value(data, calendar, component, :comments, [value])
      end

      defp next(<<"CONTACT", data::binary>>, calendar, component) do
        {data, contact} = ICal.Deserialize.Contact.from_ics(data)
        record_value(data, calendar, component, :contacts, [contact])
      end

      defp next(<<"CREATED", data::binary>>, calendar, component) do
        {data, params} = ICal.Deserialize.params(data)
        {data, value} = ICal.Deserialize.rest_of_line(data)

        record_value(
          data,
          calendar,
          component,
          :created,
          ICal.Deserialize.to_date(value, params, calendar)
        )
      end

      defp next(<<"DESCRIPTION", data::binary>>, calendar, component) do
        data = ICal.Deserialize.skip_params(data)
        {data, value} = ICal.Deserialize.multi_line(data)
        record_value(data, calendar, component, :description, value)
      end

      defp next(<<"DTSTART", data::binary>>, calendar, component) do
        {data, params} = ICal.Deserialize.params(data)
        {data, value} = ICal.Deserialize.rest_of_line(data)

        record_value(
          data,
          calendar,
          component,
          :dtstart,
          ICal.Deserialize.to_date(value, params, calendar)
        )
      end

      defp next(<<"DTSTAMP", data::binary>>, calendar, component) do
        {data, params} = ICal.Deserialize.params(data)
        {data, value} = ICal.Deserialize.rest_of_line(data)

        record_value(
          data,
          calendar,
          component,
          :dtstamp,
          ICal.Deserialize.to_date(value, params, calendar)
        )
      end

      defp next(<<"DURATION", data::binary>>, calendar, component) do
        data = ICal.Deserialize.skip_params(data)
        {data, duration} = ICal.Deserialize.Duration.one(data)
        record_value(data, calendar, component, :duration, duration)
      end

      defp next(<<"EXDATE", data::binary>>, calendar, component) do
        {data, params} = ICal.Deserialize.params(data)
        {data, value} = ICal.Deserialize.rest_of_line(data)
        date = ICal.Deserialize.to_date(value, params, calendar)
        record_value(data, calendar, component, :exdates, [date])
      end

      defp next(<<"GEO", data::binary>>, calendar, component) do
        data = ICal.Deserialize.skip_params(data)
        {data, value} = ICal.Deserialize.rest_of_line(data)
        geo = ICal.Deserialize.parse_geo(value)
        record_value(data, calendar, component, :geo, geo)
      end

      defp next(<<"LAST-MODIFIED", data::binary>>, calendar, component) do
        {data, params} = ICal.Deserialize.params(data)
        {data, value} = ICal.Deserialize.rest_of_line(data)

        record_value(
          data,
          calendar,
          component,
          :modified,
          ICal.Deserialize.to_date(value, params, calendar)
        )
      end

      defp next(<<"LOCATION", data::binary>>, calendar, component) do
        data = ICal.Deserialize.skip_params(data)
        {data, value} = ICal.Deserialize.rest_of_line(data)
        record_value(data, calendar, component, :location, value)
      end

      defp next(<<"ORGANIZER", data::binary>>, calendar, component) do
        data = ICal.Deserialize.skip_params(data)
        {data, value} = ICal.Deserialize.rest_of_line(data)
        record_value(data, calendar, component, :organizer, value)
      end

      defp next(<<"PRIORITY", data::binary>>, calendar, component) do
        data = ICal.Deserialize.skip_params(data)
        {data, value} = ICal.Deserialize.rest_of_line(data)

        record_integer_value(data, calendar, component, :priority, value)
      end

      defp next(<<"RECURRENCE-ID", data::binary>>, calendar, component) do
        {data, params} = ICal.Deserialize.params(data)
        {data, value} = ICal.Deserialize.rest_of_line(data)

        record_value(
          data,
          calendar,
          component,
          :recurrence_id,
          ICal.Deserialize.to_date(value, params, calendar)
        )
      end

      defp next(<<"RELATED-TO", data::binary>>, calendar, component) do
        data = ICal.Deserialize.skip_params(data)
        {data, value} = ICal.Deserialize.rest_of_line(data)
        record_value(data, calendar, component, :related_to, [value])
      end

      defp next(<<"RESOURCES", data::binary>>, calendar, component) do
        data = ICal.Deserialize.skip_params(data)
        {data, value} = ICal.Deserialize.comma_separated_list(data)
        record_value(data, calendar, component, :resources, value)
      end

      defp next(<<"RDATE", data::binary>>, calendar, component) do
        {data, params} = ICal.Deserialize.params(data)
        {data, values} = ICal.Deserialize.comma_separated_list(data)
        type = Map.get(params, "VALUE", "DATE")

        rdates =
          values
          |> Enum.reduce([], fn value, acc -> to_rdate(type, params, value, calendar, acc) end)
          |> Enum.reverse()

        record_value(data, calendar, component, :rdates, rdates)
      end

      defp next(<<"REQUEST-STATUS", data::binary>>, calendar, component) do
        {data, status} = ICal.Deserialize.RequestStatus.one(data)
        record_value(data, calendar, component, :request_status, [status])
      end

      defp next(<<"RRULE", data::binary>>, calendar, component) do
        data = ICal.Deserialize.skip_params(data)
        {data, values} = ICal.Deserialize.param_list(data)

        rrule = ICal.Deserialize.Recurrence.from_params(values)
        record_value(data, calendar, component, :rrule, rrule)
      end

      defp next(<<"SEQUENCE", data::binary>>, calendar, component) do
        data = ICal.Deserialize.skip_params(data)
        {data, value} = ICal.Deserialize.rest_of_line(data)
        record_integer_value(data, calendar, component, :sequence, value)
      end

      defp next(<<"STATUS", data::binary>>, calendar, component) do
        data = ICal.Deserialize.skip_params(data)
        {data, value} = ICal.Deserialize.multi_line(data)
        status = to_status(value)
        record_value(data, calendar, component, :status, status)
      end

      defp next(<<"SUMMARY", data::binary>>, calendar, component) do
        data = ICal.Deserialize.skip_params(data)
        {data, value} = ICal.Deserialize.multi_line(data)
        record_value(data, calendar, component, :summary, value)
      end

      defp next(<<"UID", data::binary>>, calendar, component) do
        data = ICal.Deserialize.skip_params(data)

        {data, value} = ICal.Deserialize.multi_line(data)

        record_value(data, calendar, component, :uid, value)
      end

      defp next(<<"URL", data::binary>>, calendar, component) do
        data = ICal.Deserialize.skip_params(data)
        {data, value} = ICal.Deserialize.multi_line(data)
        record_value(data, calendar, component, :url, value)
      end

      # prcomponent losing other non-standard headers
      defp next(<<"X-", data::binary>>, calendar, component) do
        {data, key} = ICal.Deserialize.rest_of_key(data, "X-")
        {data, params} = ICal.Deserialize.params(data)
        {data, value} = ICal.Deserialize.rest_of_line(data)

        custom_entry = %{params: params, value: value}
        custom_properties = Map.put(component.custom_properties, key, custom_entry)
        next(data, calendar, %{component | custom_properties: custom_properties})
      end
    end
  end

  defmacro trailing_parsers(component_name) do
    end_tag = "END:#{component_name}"

    quote do
      defp next(<<unquote(end_tag), data::binary>>, _calendar, event) do
        {data, event}
      end

      defp next(data, calendar, event) do
        data
        |> ICal.Deserialize.skip_line()
        |> next(calendar, event)
      end
    end
  end

  defmacro helpers do
    quote do
      # a helper that skips empty values, concats lists, then moves to the next
      defp record_value(data, calendar, component, _key, nil), do: next(data, calendar, component)
      defp record_value(data, calendar, component, _key, []), do: next(data, calendar, component)

      defp record_value(data, calendar, component, _key, [nil]),
        do: next(data, calendar, component)

      defp record_value(data, calendar, component, key, value) when is_list(value) do
        next(data, calendar, Map.put(component, key, Map.get(component, key, []) ++ value))
      end

      defp record_value(data, calendar, component, key, value) do
        next(data, calendar, Map.put(component, key, value))
      end

      defp record_integer_value(data, calendar, event, key, value) do
        case ICal.Deserialize.to_integer(value) do
          nil -> next(data, calendar, event)
          integer -> next(data, calendar, Map.put(event, key, integer))
        end
      end

      defp to_status("TENTATIVE"), do: :tentative
      defp to_status("CONFIRMED"), do: :confirmed
      defp to_status("CANCELLED"), do: :cancelled
      defp to_status(_), do: nil

      defp to_rdate("DATE", params, value, calendar, acc) do
        case ICal.Deserialize.to_date(value, params, calendar) do
          nil -> acc
          date -> [date | acc]
        end
      end

      defp to_rdate("PERIOD", params, value, calendar, acc) do
        with [first, second] <- String.split(value, "/", parts: 2),
             p_start when p_start != nil <- ICal.Deserialize.to_date(first, params, calendar),
             p_end when p_end != nil <- to_period_end(second, params, calendar) do
          [{p_start, p_end} | acc]
        else
          _ -> acc
        end
      end

      defp to_rdate(_unrecognized, _params, _value, _calendar, acc), do: acc

      defp to_period_end(end_string, params, calendar) do
        date = ICal.Deserialize.to_date(end_string, params, calendar)

        if date == nil do
          {_, duration} = ICal.Deserialize.Duration.one(end_string)
          duration
        else
          date
        end
      end
    end
  end
end
