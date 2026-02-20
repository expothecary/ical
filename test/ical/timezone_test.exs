defmodule ICal.TimezoneTest do
  use ExUnit.Case

  alias ICal.Test.Fixtures
  alias ICal.Test.Helper

  def rule_separator(["RRULE:FREQ=", _freq, _props, ?\n] = rrule, {cal, rrules}) do
    {cal, rrules ++ [to_string(rrule)]}
  end

  def rule_separator(list, acc) when is_list(list) do
    separate_rrules(list, acc)
  end

  def rule_separator(line, {cal, rrules}) do
    {cal ++ [line], rrules}
  end

  def separate_rrules(ics) do
    separate_rrules(ics, {[], []})
  end

  def separate_rrules(ics, acc) do
    Enum.reduce(ics, acc, &rule_separator/2)
  end

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

  test "Desierializing an empty buffer returns nil" do
    assert {"", nil} == ICal.Deserialize.Timezone.one("")
  end

  test "Desierializing an unterminated timezone does nothing" do
    assert %ICal{timezones: tz} = ICal.from_ics(Helper.test_data("timezone_broken"))
    assert Enum.empty?(tz)
  end

  test "Serializing a calendar with timezones" do
    calendar = %ICal{
      timezones: [Fixtures.timezone("America/New_York3"), Fixtures.timezone("Fictitious")]
    }

    # separate out the rrules as they are not stable in serialization due to map iteration order
    {calendar_parts, rrules} = ICal.to_ics(calendar) |> separate_rrules()

    assert Helper.test_data("timezones_serialized") == to_string(calendar_parts)

    # just check the count of recurrence rules; rule serialization is tested in the recurrence tests
    assert Enum.count(rrules) == 4
  end
end
