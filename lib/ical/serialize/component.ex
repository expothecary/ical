defmodule ICal.Serialize.Component do
  @moduledoc false

  defmacro parameter_serializers() do
    quote do
      defp to_ics({_key, ""}, acc), do: acc
      defp to_ics({key, nil}, acc) when key != :dtstamp, do: acc
      defp to_ics({_key, []}, acc), do: acc

      defp to_ics({:attachments, value}, acc) do
        acc ++ [Enum.map(value, &ICal.Serialize.Attachment.to_ics/1)]
      end

      defp to_ics({:attendees, attendees}, acc) do
        entries = Enum.map(attendees, &ICal.Serialize.Attendee.to_ics/1)
        acc ++ [entries]
      end

      defp to_ics({:alarms, alarms}, acc) do
        entries = Enum.map(alarms, &ICal.Serialize.Alarm.to_ics/1)
        acc ++ [entries]
      end

      defp to_ics({:custom_properties, custom_properties}, acc) do
        ICal.Serialize.add_custom_properties(acc, custom_properties)
      end

      defp to_ics({:categories, value}, acc) do
        acc ++ [ICal.Serialize.to_comma_list_kv("CATEGORIES", value)]
      end

      defp to_ics({:comments, value}, acc) do
        acc ++ [Enum.map(value, &ICal.Serialize.kv_to_ics("COMMENT", &1))]
      end

      defp to_ics({:contacts, value}, acc) do
        acc ++ [Enum.map(value, &ICal.Serialize.Contact.to_ics(&1))]
      end

      defp to_ics({:created, value}, acc) do
        acc ++ [ICal.Serialize.date_to_ics("CREATED", value)]
      end

      defp to_ics({:dtstamp, value}, acc) do
        stamp = if value == nil, do: DateTime.utc_now(), else: value

        acc ++ [ICal.Serialize.date_to_ics("DTSTAMP", stamp)]
      end

      defp to_ics({:dtstart, value}, acc) do
        acc ++ [ICal.Serialize.date_to_ics("DTSTART", value)]
      end

      defp to_ics({:duration, value}, acc) do
        acc ++ [ICal.Serialize.kv_to_ics("DURATION", value)]
      end

      defp to_ics({:exdates, value}, acc) when is_list(value) do
        acc ++ [Enum.map(value, &ICal.Serialize.date_to_ics("EXDATE", &1))]
      end

      defp to_ics({:geo, _} = geo, acc) do
        acc ++ ICal.Serialize.to_ics(geo)
      end

      defp to_ics({:priority, value}, acc) do
        if value > 0 do
          acc ++ [ICal.Serialize.kv_to_ics("PRIORITY", value)]
        else
          acc
        end
      end

      defp to_ics({:sequence, value}, acc) do
        if value > 0 do
          acc ++ [ICal.Serialize.kv_to_ics("SEQUENCE", value)]
        else
          acc
        end
      end

      defp to_ics({:resources, value}, acc) do
        acc ++ [ICal.Serialize.to_comma_list_kv("RESOURCES", value)]
      end

      defp to_ics({:request_status, values}, acc) do
        acc ++ Enum.map(values, fn status -> ICal.Serialize.RequestStatus.to_ics(status) end)
      end

      defp to_ics({:rdates, dates}, acc) when is_list(dates) do
        ICal.Serialize.Rdate.to_ics(dates, acc)
      end

      defp to_ics({:related_to, value}, acc) do
        acc ++ [Enum.map(value, &ICal.Serialize.kv_to_ics("RELATED-TO", &1))]
      end

      defp to_ics({:recurrence_id, value}, acc) do
        acc ++ [ICal.Serialize.date_to_ics("RECURRENCE-ID", value)]
      end

      defp to_ics({:rrule, rule}, acc) do
        acc ++ ICal.Serialize.Recurrence.to_ics(rule)
      end

      defp to_ics({:status, value}, acc) do
        acc ++
          case value do
            :tentative -> ["STATUS:TENTATIVE\n"]
            :confirmed -> ["STATUS:CONFIRMED\n"]
            :cancelled -> ["STATUS:CANCELLED\n"]
            :needs_action -> ["STATUS:NEEDS-ACTION\n"]
            :in_process -> ["STATUS:IN-PROCESS\n"]
            :draft -> ["STATUS:DRAFT\̣n"]
            :final -> ["STATUS:FINAL\n"]
            value -> [ICal.Serialize.kv_to_ics("STATUS", to_string(value))]
          end
      end
    end
  end

  defmacro trailing_serializers() do
    quote do
      defp to_ics({key, value}, acc) when is_number(value) do
        name = ICal.Serialize.atom_to_value(key)
        acc ++ [name, ?:, to_string(value), ?\n]
      end

      defp to_ics({key, value}, acc) when is_atom(value) do
        name = ICal.Serialize.atom_to_value(key)
        value = ICal.Serialize.atom_to_value(value)
        acc ++ [name, ?:, to_string(value), ?\n]
      end

      defp to_ics({key, value}, acc) do
        name = ICal.Serialize.atom_to_value(key)
        acc ++ [ICal.Serialize.kv_to_ics(name, value)]
      end
    end
  end
end
