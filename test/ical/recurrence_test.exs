defmodule ICal.RecurrenceTest do
  use ExUnit.Case

  alias ICal.Test.Fixtures
  alias ICal.Test.Helper

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
  end

  describe "RRULE: generating recurrences" do
    test "event with no recurrences" do
      assert [] ==
               Fixtures.one_event()
               |> ICal.Recurrence.stream()
               |> Enum.to_list()
    end

    test "daily reccuring event with until" do
      events =
        Helper.test_data("recurrance_daily_until")
        |> ICal.from_ics()
        |> Map.get(:events)
        |> Enum.map(fn event ->
          recurrences =
            ICal.Recurrence.stream(event)
            |> Enum.to_list()

          [event | recurrences]
        end)
        |> List.flatten()

      assert events |> Enum.count() == 8

      [event | events] = events
      assert event.dtstart == ~U[2015-12-24 08:30:00Z]
      [event | events] = events
      assert event.dtstart == ~U[2015-12-25 08:30:00Z]
      [event | events] = events
      assert event.dtstart == ~U[2015-12-26 08:30:00Z]
      [event | events] = events
      assert event.dtstart == ~U[2015-12-27 08:30:00Z]
      [event | events] = events
      assert event.dtstart == ~U[2015-12-28 08:30:00Z]
      [event | events] = events
      assert event.dtstart == ~U[2015-12-29 08:30:00Z]
      [event | events] = events
      assert event.dtstart == ~U[2015-12-30 08:30:00Z]
      [event] = events
      assert event.dtstart == ~U[2015-12-31 08:30:00Z]
    end

    test "daily reccuring event with count" do
      events =
        Helper.test_data("recurrance_with_count")
        |> ICal.from_ics()
        |> Map.get(:events)
        |> Enum.map(fn event ->
          recurrences =
            ICal.Recurrence.stream(event)
            |> Enum.to_list()

          [event | recurrences]
        end)
        |> List.flatten()

      assert events |> Enum.count() == 3

      [event | events] = events
      assert event.dtstart == ~U[2015-12-24 08:30:00Z]
      [event | _events] = events
      assert event.dtstart == ~U[2015-12-25 08:30:00Z]
    end

    test "monthly reccuring event with until" do
      events =
        Helper.test_data("recurrance_with_until_monthly")
        |> ICal.from_ics()
        |> Map.get(:events)
        |> Enum.map(fn event ->
          recurrences =
            ICal.Recurrence.stream(event)
            |> Enum.to_list()

          [event | recurrences]
        end)
        |> List.flatten()

      assert events |> Enum.count() == 7

      [event | events] = events
      assert event.dtstart == ~U[2015-12-24 08:30:00Z]
      [event | events] = events
      assert event.dtstart == ~U[2016-01-24 08:30:00Z]
      [event | events] = events
      assert event.dtstart == ~U[2016-02-24 08:30:00Z]
      [event | events] = events
      assert event.dtstart == ~U[2016-03-24 08:30:00Z]
      [event | events] = events
      assert event.dtstart == ~U[2016-04-24 08:30:00Z]
      [event | events] = events
      assert event.dtstart == ~U[2016-05-24 08:30:00Z]
      [event] = events
      assert event.dtstart == ~U[2016-06-24 08:30:00Z]
    end

    test "weekly reccuring event with until" do
      events =
        Helper.test_data("recurrance_with_until_weekly")
        |> ICal.from_ics()
        |> Map.get(:events)
        |> Enum.map(fn event ->
          recurrences =
            ICal.Recurrence.stream(event)
            |> Enum.to_list()

          [event | recurrences]
        end)
        |> List.flatten()

      assert events |> Enum.count() == 6

      [event | events] = events
      assert event.dtstart == ~U[2015-12-24 08:30:00Z]
      [event | events] = events
      assert event.dtstart == ~U[2015-12-31 08:30:00Z]
      [event | events] = events
      assert event.dtstart == ~U[2016-01-07 08:30:00Z]
      [event | events] = events
      assert event.dtstart == ~U[2016-01-14 08:30:00Z]
      [event | events] = events
      assert event.dtstart == ~U[2016-01-21 08:30:00Z]
      [event] = events
      assert event.dtstart == ~U[2016-01-28 08:30:00Z]
    end

    test "exdates not included in reccuring event with until and byday, ignoring invalid byday value" do
      events =
        Helper.test_data("recurrence_until_byday")
        |> ICal.from_ics()
        |> Map.get(:events)
        |> Enum.map(fn event ->
          recurrences =
            ICal.Recurrence.stream(event)
            |> Enum.to_list()

          [event | recurrences]
        end)
        |> List.flatten()

      assert events |> Enum.count() == 5

      [event | events] = events
      assert event.dtstart == ~U[2020-09-03 14:30:00Z]
      [event | events] = events
      assert event.dtstart == ~U[2020-09-30 14:30:00Z]
      [event | events] = events
      assert event.dtstart == ~U[2020-10-01 14:30:00Z]
      [event | events] = events
      assert event.dtstart == ~U[2020-10-14 14:30:00Z]
      [event] = events
      assert event.dtstart == ~U[2020-10-15 14:30:00Z]
    end
  end

  describe "RRULE: generate with yearly frequence" do
    test "simple" do
      count = 5
      rule = %ICal.Recurrence{frequency: :yearly, count: count}
      dtstart = ~U[2026-04-15 13:00:00Z]

      recurrences = ICal.Recurrence.Generate.all(rule, dtstart)

      assert Enum.count(recurrences) == count
    end

    test "by month" do
      count = 5
      rule = %ICal.Recurrence{frequency: :yearly, count: count, by_month: [1, 4, 6]}
      dtstart = ~U[2026-04-15 13:00:00Z]

      recurrences = ICal.Recurrence.Generate.all(rule, dtstart)

      assert Enum.count(recurrences) == count
      [recurrence | _] = recurrences
      assert recurrence.month == 6
    end

    test "positive set position" do
      count = 5

      rule = %ICal.Recurrence{
        frequency: :yearly,
        count: count,
        by_month: [1, 4, 6],
        by_set_position: 1
      }

      dtstart = ~U[2026-04-15 13:00:00Z]

      recurrences = ICal.Recurrence.Generate.all(rule, dtstart)

      assert Enum.count(recurrences) == count
    end

    test "negative set position" do
      count = 5

      rule = %ICal.Recurrence{
        frequency: :yearly,
        count: count,
        by_month: [1, 4, 6],
        by_set_position: -1
      }

      dtstart = ~U[2026-04-15 13:00:00Z]

      recurrences = ICal.Recurrence.Generate.all(rule, dtstart)

      assert Enum.count(recurrences) == count
      [recurrence | _] = recurrences
      assert recurrence.month == 6
    end

    test "by week number" do
      count = 22
      rule = %ICal.Recurrence{frequency: :yearly, count: count, by_week_number: [3, 17]}
      dtstart = ~U[2026-04-15 13:00:00Z]

      recurrences = ICal.Recurrence.Generate.all(rule, dtstart)

      assert Enum.count(recurrences) == count

      assert [
               ~U[2026-04-20 13:00:00Z],
               ~U[2026-04-21 13:00:00Z],
               ~U[2026-04-22 13:00:00Z],
               ~U[2026-04-23 13:00:00Z],
               ~U[2026-04-24 13:00:00Z],
               ~U[2026-04-25 13:00:00Z],
               ~U[2026-04-26 13:00:00Z],
               ~U[2027-01-18 13:00:00Z],
               ~U[2027-01-19 13:00:00Z],
               ~U[2027-01-20 13:00:00Z],
               ~U[2027-01-21 13:00:00Z],
               ~U[2027-01-22 13:00:00Z],
               ~U[2027-01-23 13:00:00Z],
               ~U[2027-01-24 13:00:00Z],
               ~U[2027-04-26 13:00:00Z],
               ~U[2027-04-27 13:00:00Z],
               ~U[2027-04-28 13:00:00Z],
               ~U[2027-04-29 13:00:00Z],
               ~U[2027-04-30 13:00:00Z],
               ~U[2027-05-01 13:00:00Z],
               ~U[2027-05-02 13:00:00Z],
               ~U[2028-01-17 13:00:00Z]
             ] == recurrences
    end

    test "by week number applied to by month" do
      count = 5

      rule = %ICal.Recurrence{
        frequency: :yearly,
        count: count,
        by_month: [1, 4, 6],
        by_week_number: [2, 17]
      }

      dtstart = ~U[2026-04-15 13:00:00Z]

      recurrences = ICal.Recurrence.Generate.all(rule, dtstart)

      assert Enum.count(recurrences) == count

      assert [
               ~U[2027-01-15 13:00:00Z],
               ~U[2028-01-15 13:00:00Z],
               ~U[2033-01-15 13:00:00Z],
               ~U[2034-01-15 13:00:00Z],
               ~U[2038-01-15 13:00:00Z]
             ] == recurrences
    end

    test "by year day" do
      count = 5
      rule = %ICal.Recurrence{frequency: :yearly, count: count, by_year_day: [15, 50]}
      dtstart = ~U[2026-04-15 13:00:00Z]

      recurrences = ICal.Recurrence.Generate.all(rule, dtstart)

      assert Enum.count(recurrences) == count

      assert [
               ~U[2027-01-15 13:00:00Z],
               ~U[2027-02-19 13:00:00Z],
               ~U[2028-01-15 13:00:00Z],
               ~U[2028-02-19 13:00:00Z],
               ~U[2029-01-15 13:00:00Z]
             ] == recurrences
    end

    test "by year day applied to by month" do
      count = 5

      rule = %ICal.Recurrence{
        frequency: :yearly,
        count: count,
        by_month: [1, 4, 6],
        by_year_day: [15, 50]
      }

      dtstart = ~U[2026-04-15 13:00:00Z]

      recurrences = ICal.Recurrence.Generate.all(rule, dtstart)

      assert Enum.count(recurrences) == count

      assert [
               ~U[2027-01-15 13:00:00Z],
               ~U[2028-01-15 13:00:00Z],
               ~U[2029-01-15 13:00:00Z],
               ~U[2030-01-15 13:00:00Z],
               ~U[2031-01-15 13:00:00Z]
             ] == recurrences
    end
  end

  describe "RRULE: generate with daily frequence" do
    test "every day in january for 3 years" do
      dtstart = DateTime.new!(~D[1998-01-31], ~T[09:00:00], "America/New_York")
      rule = ICal.Recurrence.from_ics("RRULE:FREQ=DAILY;UNTIL=20000131T140000Z;BYMONTH=1")

      Helper.time(
        fn -> ICal.Recurrence.Generate.all(rule, dtstart) end,
        "every day in january for 3 years"
      )
    end

    test "every january 10th and 31st for 3 years" do
      dtstart = DateTime.new!(~D[1998-01-31], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics(
          "RRULE:FREQ=DAILY;UNTIL=20000131T140000Z;BYMONTH=1;BYMONTHDAY=10,31"
        )

      Helper.time(
        fn -> ICal.Recurrence.Generate.all(rule, dtstart) end,
        "every 10th and 31st in january for 3 years"
      )
    end

    test "every Tuesday and Thursday in january for 3 years" do
      dtstart = DateTime.new!(~D[2026-01-31], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics("RRULE:FREQ=DAILY;UNTIL=20280131T140000Z;BYMONTH=1;BYDAY=TH,TU")

      Helper.time(
        fn -> ICal.Recurrence.Generate.all(rule, dtstart) end,
        "every 10th and 31st in january for 3 years"
      )
    end
  end

  describe "RRULE: generate with weekly frequency" do
    test "weekly for 10 weeks" do
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")
      rule = ICal.Recurrence.from_ics("RRULE:FREQ=WEEKLY;COUNT=10")

      Helper.time(fn -> ICal.Recurrence.Generate.all(rule, dtstart) end, "weekly for 10 weeks")
      #        ==> (1997 9:00 AM EDT) September 2,9,16,23,30;October 7,14,21
      #            (1997 9:00 AM EST) October 28;November 4
    end
  end
end
