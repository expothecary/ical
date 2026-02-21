defmodule ICal.Serialize.Timezone do
  @moduledoc false

  alias ICal.Serialize

  @spec component(ICal.Timezone.t()) :: iolist()
  def component(%ICal.Timezone{} = timezone) do
    contents =
      []
      |> add_id(timezone)
      |> add_modified(timezone)
      |> add_url(timezone)
      |> add_properties("STANDARD", timezone.standard)
      |> add_properties("DAYLIGHT", timezone.daylight)
      |> Serialize.add_custom_properties(timezone.custom_properties)

    [
      "BEGIN:VTIMEZONE\n",
      contents,
      "END:VTIMEZONE\n"
    ]
  end

  defp add_id(acc, %{id: id}), do: acc ++ ["TZID:", id, ?\n]

  defp add_modified(acc, %{modified: nil}), do: acc

  defp add_modified(acc, %{modified: date}) do
    acc ++ ["LAST-MODIFIED:", Serialize.value(date), ?\n]
  end

  defp add_url(acc, %{url: nil}), do: acc

  defp add_url(acc, %{url: url}) do
    acc ++ ["TZURL:", Serialize.value(url), ?\n]
  end

  defp add_properties(acc, type, definitions) do
    acc ++
      Enum.map(definitions, fn %ICal.Timezone.Properties{offsets: offsets} = definition ->
        [
          "BEGIN:",
          type,
          "\nDTSTART:",
          Serialize.value(definition.dtstart),
          "\nTZOFFSETFROM:",
          Serialize.value(offsets.from),
          "\nTZOFFSETTO:",
          Serialize.value(offsets.to),
          ?\n
        ]
        |> add_recurrence_rule(definition)
        |> add_rdates(definition)
        |> add_names(definition)
        |> add_comments(definition)
        |> Serialize.add_custom_properties(definition.custom_properties)
        |> add_property_closing(type)
      end)
  end

  defp add_recurrence_rule(acc, %{rrule: nil}), do: acc

  defp add_recurrence_rule(acc, %{rrule: rule}) do
    acc ++ [Serialize.Recurrence.property(rule)]
  end

  defp add_rdates(acc, %{rdates: rdates}) do
    acc ++ Enum.map(rdates, fn rdate -> ["RDATE:", Serialize.value(rdate), ?\n] end)
  end

  defp add_names(acc, %{names: names}) do
    acc ++ Enum.map(names, fn name -> ["TZNAME:", Serialize.value(name), ?\n] end)
  end

  defp add_comments(acc, %{comments: comments}) do
    acc ++
      Enum.map(comments, fn comment -> ["COMMENT:", Serialize.value(comment), ?\n] end)
  end

  defp add_property_closing(acc, type) do
    acc ++ ["END:", type, ?\n]
  end
end
