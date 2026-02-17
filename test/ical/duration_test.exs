defmodule ICal.DurationTest do
  use ExUnit.Case

  alias ICal.Duration

  alias ICal.Deserialize.Duration, as: Deserialize
  alias ICal.Serialize.Duration, as: Serialize

  def durations(:internal) do
    [
      {%Duration{weeks: 0, days: 12, time: {0, 0, 0}}, "P12D"},
      {%Duration{positive: false, weeks: 0, days: 12, time: {0, 0, 0}}, "-P12D"},
      {%Duration{weeks: 12, days: 0, time: {0, 0, 0}}, "P12W"},
      {%Duration{weeks: 1, days: 2, time: {0, 0, 0}}, "P2D1W"},
      {%Duration{weeks: 0, days: 0, time: {0, 15, 0}}, "PT15M"},
      {%Duration{weeks: 0, days: 0, time: {1, 0, 0}}, "PT1H"},
      {%Duration{weeks: 0, days: 0, time: {0, 1, 0}}, "PT1M"},
      {%Duration{weeks: 0, days: 0, time: {0, 0, 1}}, "PT1S"},
      {%Duration{weeks: 0, days: 0, time: {1, 2, 3}}, "PT1H2M3S"},
      {%Duration{weeks: 4, days: 5, time: {1, 2, 3}}, "P5D4WT1H2M3S"},
      {%Duration{weeks: 0, days: 5, time: {1, 2, 3}}, "P5DT1H2M3S"},
      {%Duration{weeks: 4, days: 0, time: {1, 2, 3}}, "P4WT1H2M3S"},
      {%Duration{weeks: 4, days: 5, time: {1, 2, 3}}, "P5D4WT1H2M3S"}
    ]
  end

  def durations(:external) do
    durations(:internal) ++
      [
        {%Duration{weeks: 0, days: 12, time: {0, 0, 0}}, "+P12D"},
        {%Duration{weeks: 4, days: 5, time: {1, 2, 3}}, "PT1H2M3S5D4W"},
        {%Duration{weeks: 4, days: 5, time: {1, 2, 3}}, "P4W5DT1H2M3S"}
      ]
  end

  test "ICal.Duration deserialization" do
    assert {"", nil} = Deserialize.one("")
    assert {"", nil} = Deserialize.one("\n")
    assert {"", nil} = Deserialize.one("T\n")
    assert {"NEXT", nil} = Deserialize.one("T\nNEXT")
    assert {"", %Duration{}} = Deserialize.one("P\n")
    assert {"", %Duration{}} = Deserialize.one("-P\n")

    for {duration, string} <- durations(:external) do
      assert {"", duration} == Deserialize.one(string)
    end
  end

  test "ICal.Duration serialization" do
    for {duration, string} <- durations(:internal) do
      assert Serialize.to_ics(duration) == string
    end
  end
end
