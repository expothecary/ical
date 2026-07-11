defmodule ICal.RecurrenceParsingTest do
  use ExUnit.Case

  alias ICal.Test.Fixtures

  describe "RRULE: serialization" do
    test "Serializes correctly" do
      ics =
        Fixtures.recurrence_event()
        |> ICal.to_ics()
        |> to_string()

      # Extract RRULE line for comparison (parameter order doesn't matter per RFC 5545)
      [rrule_line] = Regex.run(~r/RRULE:(.+)/, ics, capture: :all_but_first)

      rrule_params =
        rrule_line
        |> String.split(";")
        |> MapSet.new()

      expected_params =
        MapSet.new([
          "BYDAY=WE1FR-2SA",
          "BYHOUR=3",
          "BYMINUTE=2",
          "BYMONTH=10",
          "BYMONTHDAY=6",
          "BYSECOND=1",
          "BYSETPOS=20",
          "BYWEEKNO=-1",
          "BYYEARDAY=7,8,9",
          "COUNT=3",
          "FREQ=DAILY",
          "INTERVAL=1",
          "UNTIL=20191124T084500Z",
          "WKST=MONDAY"
        ])

      assert rrule_params == expected_params
    end

    test "weekday abbreviations handled corrrectly" do
      rrule = %{"FREQ" => "DAILY", "BYDAY" => "-1SU,SU,1MO,-1TU,+2WE,TH,FR,SA,GA,GARBAGE,,0,-1"}

      recurrence = %ICal.Recurrence{
        frequency: :daily,
        by_day: [
          {0, :thursday},
          {0, :friday},
          {0, :saturday},
          {0, :sunday},
          {1, :monday},
          {2, :wednesday},
          {-1, :tuesday},
          {-1, :sunday}
        ]
      }

      assert recurrence === ICal.Deserialize.Recurrence.from_params(rrule)

      serialized = ICal.Serialize.Recurrence.property(recurrence) |> to_string()

      assert String.starts_with?(serialized, "RRULE:FREQ=DAILY")
      assert String.contains?(serialized, ";INTERVAL=1")
      assert String.contains?(serialized, ";BYDAY=THFRSASU1MO2WE-1TU-1SU")
      assert String.ends_with?(serialized, "\n")
    end
  end

  describe "RRULE: deserialization" do
    test "ignores bad WKST values" do
      rrule = %{"FREQ" => "DAILY", "WKST" => "NO"}

      assert %ICal.Recurrence{frequency: :daily, week_start_day: :default} ===
               ICal.Deserialize.Recurrence.from_params(rrule)
    end

    test "clamps time values" do
      rrule = %{
        "FREQ" => "DAILY",
        "BYSECOND" => "-1,-,0,1,10,50,59,60,70",
        "BYMINUTE" => "-1,-,0,1,10,50,59,60,70",
        "BYHOUR" => "-1,-,0,1,6,12,23,24"
      }

      assert %ICal.Recurrence{
               frequency: :daily,
               by_second: [0, 1, 10, 50, 59],
               by_minute: [0, 1, 10, 50, 59],
               by_hour: [0, 1, 6, 12, 23]
             } === ICal.Deserialize.Recurrence.from_params(rrule)
    end

    test "clamps day/week/month values" do
      rrule = %{
        "FREQ" => "DAILY",
        "BYWEEKNO" => "-54,-53,-1,0,a,1,25,2,53,54",
        "BYMONTHDAY" => "-32,-31,a,-1,1,31,32",
        "BYMONTH" => "0,1,12,a,13",
        "BYYEARDAY" => "-367,-366,-1,0,a,,1,366,367,garbage",
        "BYSETPOS" => "-367,-366,-1,0,a,,1,366,367"
      }

      assert %ICal.Recurrence{
               frequency: :daily,
               by_week_number: [-53, -1, 1, 2, 25, 53],
               by_month_day: [-31, -1, 1, 31],
               by_month: [1, 12],
               by_year_day: [-366, -1, 1, 366],
               by_set_position: [-366, -1, 1, 366]
             } === ICal.Deserialize.Recurrence.from_params(rrule)
    end

    test "ignores garbage in count and interval" do
      rrule = %{
        "FREQ" => "DAILY",
        "COUNT" => "GARBAGE",
        "INTERVAL" => ""
      }

      assert %ICal.Recurrence{
               frequency: :daily,
               count: nil,
               interval: 1
             } === ICal.Deserialize.Recurrence.from_params(rrule)
    end

    test "parses values of frequency corrrectly" do
      rrule = %{"FREQ" => "DAILY"}

      assert %ICal.Recurrence{frequency: :daily} ===
               ICal.Deserialize.Recurrence.from_params(rrule)

      rrule = %{"FREQ" => "WEEKLY"}

      assert %ICal.Recurrence{frequency: :weekly} ===
               ICal.Deserialize.Recurrence.from_params(rrule)

      rrule = %{"FREQ" => "MONTHLY"}

      assert %ICal.Recurrence{frequency: :monthly} ===
               ICal.Deserialize.Recurrence.from_params(rrule)

      rrule = %{"FREQ" => "YEARLY"}

      assert %ICal.Recurrence{frequency: :yearly} ===
               ICal.Deserialize.Recurrence.from_params(rrule)

      rrule = %{"FREQ" => "HOURLY"}

      assert %ICal.Recurrence{frequency: :hourly} ===
               ICal.Deserialize.Recurrence.from_params(rrule)

      rrule = %{"FREQ" => "MINUTELY"}

      assert %ICal.Recurrence{frequency: :minutely} ===
               ICal.Deserialize.Recurrence.from_params(rrule)

      rrule = %{"FREQ" => "SECONDLY"}

      assert %ICal.Recurrence{frequency: :secondly} ===
               ICal.Deserialize.Recurrence.from_params(rrule)

      rrule = %{"FREQ" => "GARBAGE"}
      assert nil === ICal.Deserialize.Recurrence.from_params(rrule)
    end

    test "parses date UNTIL field" do
      assert %ICal.Recurrence{until: %Date{}} =
               ICal.Recurrence.from_ics("RRULE:FREQ=DAILY;UNTIL=20180415")
    end

    test "suppports single-line and line-folded rules" do
      expected = %ICal.Recurrence{
        until: ~U[2018-04-15 20:59:59Z],
        frequency: :monthly,
        by_set_position: [3],
        by_day: [{0, :monday}],
        week_start_day: :monday,
        interval: 1
      }

      Enum.each(
        [
          "RRULE:FREQ=MONTHLY;WKST=MO;UNTIL=20180415T205959Z;INTERVAL=1;BYDAY=MO;BYSETPOS=3\r\n",
          "RRULE:FREQ=MONTHLY;WKST=MO;UNTIL=20180415T205959Z;INTERVAL=1;BYDAY=MO;BYSETPOS=3",
          "RRULE:FREQ=MONTHLY;WKST=MO;UNTIL=20180415T205959Z;INTERVAL=1;BYDAY=MO;BYSET\r\n POS=3\r\n",
          "RRULE:FREQ=MONTHLY;WKST=MO;UNTIL=20180415T20\n 5959Z;INTERVAL=1;BYDAY=MO;BYSETPOS=3\n",
          "RRULE:FREQ=MONTHLY;WKST=MO;UNTIL=20180415T20\r\n 5959Z;INTERVAL=1;BYDAY=MO;BYSETPOS=3\r\n"
        ],
        fn string ->
          assert expected === ICal.Recurrence.from_ics(string)
        end
      )

      rrule =
        "RRULE:FREQ=MONTHLY;WKST=MO;UNTIL=20180415T205959Z;INTERVAL=1;BYDAY=MO;BYSET\r\nPOS=3\r\n"
        |> ICal.Recurrence.from_ics()

      assert %{expected | by_set_position: nil} === rrule
    end
  end
end
