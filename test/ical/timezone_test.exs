defmodule ICal.TimezoneTest do
  use ExUnit.Case

  alias ICal.Test.Fixtures
  alias ICal.Test.Helper

  test "Deserializing calendar with timezones" do
    calendar =
      "timezones"
      |> Helper.test_data()
      |> ICal.from_ics()

    assert Enum.count(calendar.timezones) == 5

    Enum.each(calendar.timezones, fn {name, timezone} ->
      assert timezone == Fixtures.timezone(name)
    end)
  end
end
