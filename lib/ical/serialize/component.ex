defmodule ICal.Serialize.Component do
  @moduledoc false

  # credo:disable-for-next-line
  defmacro parameter_serializers do
    quote do
      defp serialize({_key, ""}, acc), do: acc
      defp serialize({key, nil}, acc) when key != :dtstamp, do: acc
      defp serialize({_key, []}, acc), do: acc

      defp serialize({:attachments, value}, acc) do
        acc ++ [Enum.map(value, &ICal.Serialize.Attachment.property/1)]
      end

      defp serialize({:attendees, attendees}, acc) do
        entries = Enum.map(attendees, &ICal.Serialize.Attendee.property/1)
        acc ++ [entries]
      end

      defp serialize({:alarms, alarms}, acc) do
        entries = Enum.map(alarms, &ICal.Serialize.Alarm.component/1)
        acc ++ [entries]
      end

      defp serialize({:custom_properties, custom_properties}, acc) do
        ICal.Serialize.add_custom_properties(acc, custom_properties)
      end

      defp serialize({:categories, value}, acc) do
        acc ++ [ICal.Serialize.to_comma_list_kv("CATEGORIES", value)]
      end

      defp serialize({:comments, value}, acc) do
        acc ++ [Enum.map(value, &ICal.Serialize.kv("COMMENT", &1))]
      end

      defp serialize({:contacts, value}, acc) do
        acc ++ [Enum.map(value, &ICal.Serialize.Contact.property(&1))]
      end

      defp serialize({:created, value}, acc) do
        acc ++ [ICal.Serialize.date("CREATED", value)]
      end

      defp serialize({:dtstamp, value}, acc) do
        stamp = if value == nil, do: DateTime.utc_now(), else: value

        acc ++ [ICal.Serialize.date("DTSTAMP", stamp)]
      end

      defp serialize({:dtstart, value}, acc) do
        acc ++ [ICal.Serialize.date("DTSTART", value)]
      end

      defp serialize({:duration, value}, acc) do
        acc ++ [ICal.Serialize.kv("DURATION", value)]
      end

      defp serialize({:exdates, value}, acc) when is_list(value) do
        acc ++ [Enum.map(value, &ICal.Serialize.date("EXDATE", &1))]
      end

      defp serialize({:geo, _} = geo, acc) do
        acc ++ ICal.Serialize.value(geo)
      end

      defp serialize({:priority, value}, acc) do
        if value > 0 do
          acc ++ [ICal.Serialize.kv("PRIORITY", value)]
        else
          acc
        end
      end

      defp serialize({:sequence, value}, acc) do
        if value > 0 do
          acc ++ [ICal.Serialize.kv("SEQUENCE", value)]
        else
          acc
        end
      end

      defp serialize({:resources, value}, acc) do
        acc ++ [ICal.Serialize.to_comma_list_kv("RESOURCES", value)]
      end

      defp serialize({:request_status, values}, acc) do
        acc ++ Enum.map(values, fn status -> ICal.Serialize.RequestStatus.property(status) end)
      end

      defp serialize({:rdates, dates}, acc) when is_list(dates) do
        ICal.Serialize.Rdate.property(dates, acc)
      end

      defp serialize({:related_to, value}, acc) do
        acc ++ [Enum.map(value, &ICal.Serialize.kv("RELATED-TO", &1))]
      end

      defp serialize({:recurrence_id, value}, acc) do
        acc ++ [ICal.Serialize.date("RECURRENCE-ID", value)]
      end

      defp serialize({:rrule, rule}, acc) do
        acc ++ ICal.Serialize.Recurrence.property(rule)
      end

      defp serialize({:status, value}, acc) do
        acc ++
          case value do
            :tentative -> ["STATUS:TENTATIVE\n"]
            :confirmed -> ["STATUS:CONFIRMED\n"]
            :cancelled -> ["STATUS:CANCELLED\n"]
            :needs_action -> ["STATUS:NEEDS-ACTION\n"]
            :in_process -> ["STATUS:IN-PROCESS\n"]
            :draft -> ["STATUS:DRAFT\̣n"]
            :final -> ["STATUS:FINAL\n"]
            value -> [ICal.Serialize.kv("STATUS", to_string(value))]
          end
      end
    end
  end

  defmacro trailing_serializers do
    quote do
      defp serialize({key, values}, acc) when is_list(values) do
        name = ICal.Serialize.key(key)
        acc ++ Enum.map(values, fn value -> ICal.Serialize.kv(name, value) end)
      end

      defp serialize({key, value}, acc) do
        name = ICal.Serialize.key(key)
        acc ++ ICal.Serialize.kv(name, value)
      end
    end
  end
end
