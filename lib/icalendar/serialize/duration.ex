defmodule ICalendar.Serialize.Duration do
  @moduledoc false

  alias ICalendar.Duration

  def to_ics(%Duration{} = duration) do
    duration
    |> starting_string()
    |> add_days(duration)
    |> add_weeks(duration)
    |> add_time(duration)
  end

  defp starting_string(%{positive: false}), do: "-P"
  defp starting_string(_), do: "P"

  defp add_days(string, %{days: days}) when days > 0 do
    string <> "#{days}D"
  end

  defp add_days(string, _duration), do: string

  defp add_weeks(string, %{weeks: weeks}) when weeks > 0 do
    string <> "#{weeks}W"
  end

  defp add_weeks(string, _duration), do: string

  defp add_time(string, %{time: {h, m, s}}) when h < 1 and m < 1 and s < 1, do: string

  defp add_time(string, %{time: {h, m, s}}) do
    (string <> "T")
    |> add_hours(h)
    |> add_minutes(m)
    |> add_seconds(s)
  end

  defp add_hours(string, v) when v < 1, do: string
  defp add_hours(string, v), do: string <> "#{v}H"

  defp add_minutes(string, v) when v < 1, do: string
  defp add_minutes(string, v), do: string <> "#{v}M"

  defp add_seconds(string, v) when v < 1, do: string
  defp add_seconds(string, v), do: string <> "#{v}S"
end
