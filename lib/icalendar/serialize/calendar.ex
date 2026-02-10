defmodule ICalendar.Serialize.Calendar do
  def to_ics(%ICalendar{} = calendar) do
    []
    |> start_calendar(calendar)
    |> scale(calendar)
    |> version(calendar)
    |> product_id(calendar)
    |> method(calendar)
    |> events(calendar)
    |> end_calendar(calendar)
  end

  def to_ics(%ICalendar.Event{} = event) do
    ICalendar.Serialize.Event.to_ics(event)
  end

  defp start_calendar(acc, _calendar), do: acc ++ ["BEGIN:VCALENDAR\n"]
  defp end_calendar(acc, _calendar), do: acc ++ ["END:VCALENDAR\n"]

  defp scale(acc, %{scale: nil}), do: acc
  defp scale(acc, calendar), do: acc ++ ["CALSCALE:", calendar.scale, "\n"]

  defp method(acc, %{method: nil}), do: acc
  defp method(acc, calendar), do: acc ++ ["METHOD:", calendar.method, "\n"]

  defp version(acc, %{version: nil}), do: acc
  defp version(acc, calendar), do: acc ++ ["VERSION:", calendar.version, "\n"]

  defp product_id(acc, %{product_id: nil}), do: acc
  defp product_id(acc, calendar), do: acc ++ ["PRODID:", calendar.product_id, "\n"]

  defp events(acc, %{events: []}), do: acc

  defp events(acc, calendar) do
    acc ++ Enum.map(calendar.events, &ICalendar.Serialize.Event.to_ics/1)
  end
end
