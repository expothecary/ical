defmodule ICal.Serialize.Calendar do
  @moduledoc false

  alias ICal.Serialize

  def to_ics(components) when is_list(components) do
    Enum.map(components, &to_ics/1)
  end

  def to_ics(%ICal{} = calendar) do
    []
    |> start_calendar(calendar)
    |> scale(calendar)
    |> version(calendar)
    |> product_id(calendar)
    |> method(calendar)
    |> Serialize.add_custom_properties(calendar.custom_properties)
    |> timezones(calendar)
    |> events(calendar)
    |> todos(calendar)
    |> other_components(calendar)
    |> end_calendar(calendar)
  end

  def to_ics(%ICal.Event{} = event) do
    ICal.Serialize.Event.component(event)
  end

  def to_ics(%ICal.Todo{} = event) do
    ICal.Serialize.Todo.component(event)
  end

  defp start_calendar(acc, _calendar), do: acc ++ ["BEGIN:VCALENDAR\n"]
  defp end_calendar(acc, _calendar), do: acc ++ ["END:VCALENDAR\n"]

  defp scale(acc, %{scale: nil}), do: acc
  defp scale(acc, calendar), do: acc ++ ["CALSCALE:", calendar.scale, ?\n]

  defp method(acc, %{method: nil}), do: acc
  defp method(acc, calendar), do: acc ++ ["METHOD:", calendar.method, ?\n]

  defp version(acc, %{version: nil}), do: acc ++ ["VERSION:2.0\n"]
  defp version(acc, calendar), do: acc ++ ["VERSION:", calendar.version, ?\n]

  defp product_id(acc, %{product_id: nil}), do: acc ++ ["PRODID:", ICal.default_product_id(), ?\n]
  defp product_id(acc, calendar), do: acc ++ ["PRODID:", calendar.product_id, ?\n]

  defp timezones(acc, calendar) do
    acc ++ Enum.map(calendar.timezones, &ICal.Serialize.Timezone.component/1)
  end

  defp events(acc, calendar) do
    acc ++ Enum.map(calendar.events, &ICal.Serialize.Event.component/1)
  end

  defp todos(acc, calendar) do
    acc ++ Enum.map(calendar.todos, &ICal.Serialize.Todo.component/1)
  end

  defp other_components(acc, calendar) do
    acc ++ Serialize.components(calendar.__other_components)
  end
end
