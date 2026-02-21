# credo:disable-for-this-file
defmodule ICal.Deserialize.Component do
  @moduledoc false

  defmacro rejection_guards do
    quote do
      def one(<<>>, _), do: {<<>>, nil}
      def one(<<?\r, ?\n>>, _), do: {<<>>, nil}
      def one(<<?\n>>, _), do: {<<>>, nil}
    end
  end

  defmacro parameter_parsers(optional \\ [:geo, :location, :resources]) do
    [
      quote do
        defp next_parameter(<<>> = data, _calendar, component), do: {data, component}

        defp next_parameter(<<"ATTACH", data::binary>>, calendar, component) do
          {data, attachment} = ICal.Deserialize.attachment(data)
          record_value(data, calendar, component, :attachments, attachment)
        end

        defp next_parameter(<<"ATTENDEE", data::binary>>, calendar, component) do
          {data, attendee} = ICal.Deserialize.Attendee.one(data)
          record_value(data, calendar, component, :attendees, attendee)
        end

        defp next_parameter(<<"BEGIN:VALARM", data::binary>>, calendar, component) do
          {data, alarm} = ICal.Deserialize.Alarm.one(data, calendar)
          record_value(data, calendar, component, :alarms, alarm)
        end

        defp next_parameter(<<"CATEGORIES", data::binary>>, calendar, component) do
          data = ICal.Deserialize.skip_params(data)
          {data, values} = ICal.Deserialize.comma_separated_list(data)
          record_value(data, calendar, component, :categories, values)
        end

        defp next_parameter(<<"CLASS", data::binary>>, calendar, component) do
          data = ICal.Deserialize.skip_params(data)
          {data, value} = ICal.Deserialize.rest_of_line(data)
          record_value(data, calendar, component, :class, value)
        end

        defp next_parameter(<<"COMMENT", data::binary>>, calendar, component) do
          data = ICal.Deserialize.skip_params(data)
          {data, value} = ICal.Deserialize.multi_line(data)
          record_value(data, calendar, component, :comments, value)
        end

        defp next_parameter(<<"CONTACT", data::binary>>, calendar, component) do
          {data, contact} = ICal.Deserialize.Contact.from_ics(data)
          record_value(data, calendar, component, :contacts, contact)
        end

        defp next_parameter(<<"CREATED", data::binary>>, calendar, component) do
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

        defp next_parameter(<<"DESCRIPTION", data::binary>>, calendar, component) do
          data = ICal.Deserialize.skip_params(data)
          {data, value} = ICal.Deserialize.multi_line(data)
          record_value(data, calendar, component, :description, value)
        end

        defp next_parameter(<<"DTSTART", data::binary>>, calendar, component) do
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

        defp next_parameter(<<"DTSTAMP", data::binary>>, calendar, component) do
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

        defp next_parameter(<<"DURATION", data::binary>>, calendar, component) do
          data = ICal.Deserialize.skip_params(data)
          {data, duration} = ICal.Deserialize.Duration.one(data)
          record_value(data, calendar, component, :duration, duration)
        end

        defp next_parameter(<<"EXDATE", data::binary>>, calendar, component) do
          {data, params} = ICal.Deserialize.params(data)
          {data, value} = ICal.Deserialize.rest_of_line(data)
          date = ICal.Deserialize.to_date(value, params, calendar)
          record_value(data, calendar, component, :exdates, date)
        end

        defp next_parameter(<<"LAST-MODIFIED", data::binary>>, calendar, component) do
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

        defp next_parameter(<<"ORGANIZER", data::binary>>, calendar, component) do
          data = ICal.Deserialize.skip_params(data)
          {data, value} = ICal.Deserialize.rest_of_line(data)
          record_value(data, calendar, component, :organizer, value)
        end

        defp next_parameter(<<"PRIORITY", data::binary>>, calendar, component) do
          data = ICal.Deserialize.skip_params(data)
          {data, value} = ICal.Deserialize.rest_of_line(data)

          record_integer_value(data, calendar, component, :priority, value)
        end

        defp next_parameter(<<"RECURRENCE-ID", data::binary>>, calendar, component) do
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

        defp next_parameter(<<"RELATED-TO", data::binary>>, calendar, component) do
          data = ICal.Deserialize.skip_params(data)
          {data, value} = ICal.Deserialize.rest_of_line(data)
          record_value(data, calendar, component, :related_to, value)
        end

        defp next_parameter(<<"RDATE", data::binary>>, calendar, component) do
          {data, params} = ICal.Deserialize.params(data)
          {data, values} = ICal.Deserialize.comma_separated_list(data)
          type = Map.get(params, "VALUE", "DATE")

          rdates =
            values
            |> Enum.reduce([], fn value, acc -> to_rdate(type, params, value, calendar, acc) end)
            |> Enum.reverse()

          record_value(data, calendar, component, :rdates, rdates)
        end

        defp next_parameter(<<"REQUEST-STATUS", data::binary>>, calendar, component) do
          {data, status} = ICal.Deserialize.RequestStatus.one(data)
          record_value(data, calendar, component, :request_status, status)
        end

        defp next_parameter(<<"RRULE", data::binary>>, calendar, component) do
          data = ICal.Deserialize.skip_params(data)
          {data, values} = ICal.Deserialize.param_list(data)

          rrule = ICal.Deserialize.Recurrence.from_params(values)
          record_value(data, calendar, component, :rrule, rrule)
        end

        defp next_parameter(<<"SEQUENCE", data::binary>>, calendar, component) do
          data = ICal.Deserialize.skip_params(data)
          {data, value} = ICal.Deserialize.rest_of_line(data)
          record_integer_value(data, calendar, component, :sequence, value)
        end

        defp next_parameter(<<"STATUS", data::binary>>, calendar, component) do
          data = ICal.Deserialize.skip_params(data)
          {data, value} = ICal.Deserialize.multi_line(data)
          status = ICal.Deserialize.status(component, value)
          record_value(data, calendar, component, :status, status)
        end

        defp next_parameter(<<"SUMMARY", data::binary>>, calendar, component) do
          data = ICal.Deserialize.skip_params(data)
          {data, value} = ICal.Deserialize.multi_line(data)
          record_value(data, calendar, component, :summary, value)
        end

        defp next_parameter(<<"UID", data::binary>>, calendar, component) do
          data = ICal.Deserialize.skip_params(data)
          {data, value} = ICal.Deserialize.multi_line(data)
          record_value(data, calendar, component, :uid, value)
        end

        defp next_parameter(<<"URL", data::binary>>, calendar, component) do
          data = ICal.Deserialize.skip_params(data)
          {data, value} = ICal.Deserialize.multi_line(data)
          record_value(data, calendar, component, :url, value)
        end

        # prcomponent losing other non-standard headers
        defp next_parameter(<<"X-", data::binary>>, calendar, component) do
          {data, key} = ICal.Deserialize.rest_of_key(data, "X-")
          {data, params} = ICal.Deserialize.params(data)
          {data, value} = ICal.Deserialize.rest_of_line(data)

          custom_entry = %{params: params, value: value}
          custom_properties = Map.put(component.custom_properties, key, custom_entry)
          next_parameter(data, calendar, %{component | custom_properties: custom_properties})
        end
      end
    ]
    |> maybe(Enum.find(optional, &(:geo == &1)))
    |> maybe(Enum.find(optional, &(:location == &1)))
    |> maybe(Enum.find(optional, &(:resources == &1)))
  end

  defmacro trailing_parsers(component_name) do
    end_tag = "END:#{component_name}"

    quote do
      defp next_parameter(<<unquote(end_tag), data::binary>>, _calendar, event) do
        {data, event}
      end

      defp next_parameter(data, calendar, event) do
        data
        |> ICal.Deserialize.skip_line()
        |> next_parameter(calendar, event)
      end
    end
  end

  defmacro helpers do
    quote do
      # a helper that skips empty values, concats lists, then moves to the next
      defp record_value(data, calendar, component, _key, nil) do
        next_parameter(data, calendar, component)
      end

      defp record_value(data, calendar, component, _key, []) do
        next_parameter(data, calendar, component)
      end

      defp record_value(data, calendar, component, _key, [nil]) do
        next_parameter(data, calendar, component)
      end

      defp record_value(data, calendar, component, key, value) do
        component =
          case Map.get(component, key) do
            values when is_list(values) -> Map.put(component, key, values ++ List.wrap(value))
            _ -> Map.put(component, key, value)
          end

        next_parameter(data, calendar, component)
      end

      defp record_integer_value(data, calendar, event, key, value) do
        case ICal.Deserialize.to_integer(value) do
          nil -> next_parameter(data, calendar, event)
          integer -> next_parameter(data, calendar, Map.put(event, key, integer))
        end
      end

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

  defp maybe(acc, :geo) do
    acc ++
      [
        quote do
          defp next_parameter(<<"GEO", data::binary>>, calendar, component) do
            data = ICal.Deserialize.skip_params(data)
            {data, value} = ICal.Deserialize.rest_of_line(data)
            geo = ICal.Deserialize.parse_geo(value)
            record_value(data, calendar, component, :geo, geo)
          end
        end
      ]
  end

  defp maybe(acc, :location) do
    acc ++
      [
        quote do
          defp next_parameter(<<"LOCATION", data::binary>>, calendar, component) do
            data = ICal.Deserialize.skip_params(data)
            {data, value} = ICal.Deserialize.rest_of_line(data)
            record_value(data, calendar, component, :location, value)
          end
        end
      ]
  end

  defp maybe(acc, :resources) do
    acc ++
      [
        quote do
          defp next_parameter(<<"RESOURCES", data::binary>>, calendar, component) do
            data = ICal.Deserialize.skip_params(data)
            {data, value} = ICal.Deserialize.comma_separated_list(data)
            record_value(data, calendar, component, :resources, value)
          end
        end
      ]
  end

  defp maybe(acc, _), do: acc
end
