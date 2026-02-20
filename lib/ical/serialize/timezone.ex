defmodule ICal.Serialize.Timezone do
  @moduledoc false

  alias ICal.Serialize

  @spec to_ics(ICal.Timezone.t()) :: iolist()
  def to_ics(%ICal.Timezone{} = timezone) do
    contents =
      []
      |> add_id(timezone)
      |> add_last_modified(timezone)
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

  defp add_last_modified(acc, %{last_modified: nil}), do: acc

  defp add_last_modified(acc, %{last_modified: date}) do
    acc ++ ["LAST-MODIFIED:", Serialize.to_ics(date), ?\n]
  end

  defp add_url(acc, %{url: nil}), do: acc

  defp add_url(acc, %{url: url}) do
    acc ++ ["TZURL:", Serialize.to_ics(url), ?\n]
  end

  defp add_properties(acc, type, definitions) do
    acc ++
      Enum.map(definitions, fn %ICal.Timezone.Properties{offsets: offsets} = definition ->
        [
          "BEGIN:",
          type,
          "\nDTSTART:",
          Serialize.to_ics(definition.dtstart),
          "\nTZOFFSETFROM:",
          Serialize.to_ics(offsets.from),
          "\nTZOFFSETTO:",
          Serialize.to_ics(offsets.to),
          ?\n
        ]
        |> add_recurrence_rule(definition)
        |> add_rdates(definition)
        |> add_names(definition)
        |> add_comments(definition)
        |> Serialize.add_custom_properties(definition.custom_properties)
      end)
  end

  defp add_recurrence_rule(acc, %{rrule: nil}), do: acc

  defp add_recurrence_rule(acc, %{rrule: rule}) do
    acc ++ [Serialize.Recurrence.to_ics(rule)]
  end

  defp add_rdates(acc, %{rdates: rdates}) do
    acc ++ Enum.map(rdates, fn rdate -> ["RDATE:", Serialize.to_ics(rdate), ?\n] end)
  end

  defp add_names(acc, %{names: names}) do
    acc ++ Enum.map(names, fn name -> ["TZNAME:", Serialize.to_ics(name), ?\n] end)
  end

  defp add_comments(acc, %{comments: comments}) do
    acc ++
      Enum.map(comments, fn comment -> ["COMMENT:", Serialize.to_ics(comment), ?\n] end)
  end
end
