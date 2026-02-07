defmodule ICalendar.Test.Helper do
  def test_data(name) do
    Path.join([File.cwd!(), "/test/data"], name <> ".ical")
    |> File.read!()
  end

  def extract_event_props(["BEGIN:VEVENT\n", props, "END:VEVENT\n"]) do
    ["BEGIN:VEVENT\n", Enum.sort(props), "END:VEVENT\n"] |> to_string()
  end

  def extract_event_props(ics) do
    Enum.reduce(ics, [], fn
      ["BEGIN:VEVENT\n", props, "END:VEVENT\n"], acc ->
        acc ++ ["BEGIN:VEVENT\n", Enum.sort(props), "END:VEVENT\n"]

      _, acc ->
        acc
    end)
    |> to_string()
  end
end

ExUnit.start()
