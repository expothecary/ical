defmodule ICalendar.Test.Helper do
  def test_data(name) do
    Path.join([File.cwd!(), "/test/data"], name <> ".ical")
    |> File.read!()
  end
end

ExUnit.start()
