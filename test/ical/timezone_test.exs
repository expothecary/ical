defmodule ICal.TimezoneTest do
  use ExUnit.Case

  alias ICal.Test.Helper

  test "Serializing parameters lists" do
    calendar =
      "timezones"
      |> Helper.test_data()
      |> ICal.from_ics()

    assert Enum.count(calendar.timezones) == 5
  end
end
