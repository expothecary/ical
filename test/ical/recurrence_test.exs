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

  describe "Recurrence stream" do
    test "correctly handles event with no recurrences" do
      assert [] ==
               Fixtures.one_event()
               |> ICal.Recurrence.stream()
               |> Enum.to_list()
    end

    test "correctly handles event with no recurrence rule, but recurrence dates" do
      event = Fixtures.one_event(:with_rdates)

      assert event.rdates ==
               event
               |> ICal.Recurrence.stream()
               |> Enum.to_list()
    end

    test "correctly handles event with a recurrence rule and recurrence dates" do
      [event] =
        Helper.test_data("recurrance_with_count")
        |> ICal.from_ics()
        |> Map.get(:events)

      rdates = [
        ~U[2015-10-23 07:30:00Z],
        ~U[2015-10-23 09:30:00Z],
        ~U[2015-12-24 12:30:00Z],
        ~U[2015-12-25 12:30:00Z],
        ~U[2015-12-26 10:30:00Z],
        ~U[2015-12-27 09:30:00Z]
      ]

      event = %{event | rdates: rdates}

      generated = [
        ~U[2015-12-24 08:30:00Z],
        ~U[2015-12-25 08:30:00Z],
        ~U[2015-12-26 08:30:00Z]
      ]

      expected = Helper.sort_dates(rdates ++ generated)

      assert expected ==
               event
               |> ICal.Recurrence.stream()
               |> Enum.to_list()
    end

    test "generates daily reccuring event with until" do
      recurrences =
        Helper.test_data("recurrance_daily_until")
        |> ICal.from_ics()
        |> Map.get(:events)
        |> Enum.map(fn event ->
          ICal.Recurrence.stream(event)
          |> Enum.to_list()
        end)
        |> List.flatten()

      assert Enum.count(recurrences) == 8

      assert recurrences == [
               ~U[2015-12-24 08:30:00Z],
               ~U[2015-12-25 08:30:00Z],
               ~U[2015-12-26 08:30:00Z],
               ~U[2015-12-27 08:30:00Z],
               ~U[2015-12-28 08:30:00Z],
               ~U[2015-12-29 08:30:00Z],
               ~U[2015-12-30 08:30:00Z],
               ~U[2015-12-31 08:30:00Z]
             ]
    end

    test "generates daily reccuring event with count" do
      recurrences =
        Helper.test_data("recurrance_with_count")
        |> ICal.from_ics()
        |> Map.get(:events)
        |> Enum.map(fn event ->
          ICal.Recurrence.stream(event)
          |> Enum.to_list()
        end)
        |> List.flatten()

      assert Enum.count(recurrences) == 3

      assert recurrences == [
               ~U[2015-12-24 08:30:00Z],
               ~U[2015-12-25 08:30:00Z],
               ~U[2015-12-26 08:30:00Z]
             ]
    end

    test "generates monthly reccuring event with until" do
      recurrences =
        Helper.test_data("recurrance_with_until_monthly")
        |> ICal.from_ics()
        |> Map.get(:events)
        |> Enum.map(fn event ->
          ICal.Recurrence.stream(event)
          |> Enum.to_list()
        end)
        |> List.flatten()

      assert Enum.count(recurrences) == 7

      assert recurrences == [
               ~U[2015-12-24 08:30:00Z],
               ~U[2016-01-24 08:30:00Z],
               ~U[2016-02-24 08:30:00Z],
               ~U[2016-03-24 08:30:00Z],
               ~U[2016-04-24 08:30:00Z],
               ~U[2016-05-24 08:30:00Z],
               ~U[2016-06-24 08:30:00Z]
             ]
    end

    test "generates weekly reccuring event with until" do
      recurrences =
        Helper.test_data("recurrance_with_until_weekly")
        |> ICal.from_ics()
        |> Map.get(:events)
        |> Enum.map(fn event ->
          ICal.Recurrence.stream(event)
          |> Enum.to_list()
        end)
        |> List.flatten()

      assert Enum.count(recurrences) == 6

      assert recurrences == [
               ~U[2015-12-24 08:30:00Z],
               ~U[2015-12-31 08:30:00Z],
               ~U[2016-01-07 08:30:00Z],
               ~U[2016-01-14 08:30:00Z],
               ~U[2016-01-21 08:30:00Z],
               ~U[2016-01-28 08:30:00Z]
             ]
    end

    test "ensures exdates not included in reccuring event with until and byday, ignoring invalid byday value" do
      recurrences =
        Helper.test_data("recurrence_until_byday")
        |> ICal.from_ics()
        |> Map.get(:events)
        |> Enum.map(fn event ->
          ICal.Recurrence.stream(event)
          |> Enum.to_list()
        end)
        |> List.flatten()

      assert Enum.count(recurrences) == 5

      assert recurrences == [
               ~U[2020-09-03 14:30:00Z],
               ~U[2020-09-30 14:30:00Z],
               ~U[2020-10-01 14:30:00Z],
               ~U[2020-10-14 14:30:00Z],
               ~U[2020-10-15 14:30:00Z]
             ]
    end
  end

  describe "Recurrence generation with yearly frequence" do
    test "simple" do
      count = 5
      rule = %ICal.Recurrence{frequency: :yearly, count: count}
      dtstart = ~U[2026-04-15 13:00:00Z]

      {:ok, recurrences} = ICal.Recurrence.Generate.all(rule, dtstart)

      assert Enum.count(recurrences) == count
    end

    test "by month" do
      count = 5
      rule = %ICal.Recurrence{frequency: :yearly, count: count, by_month: [1, 4, 6]}
      dtstart = ~U[2026-04-15 13:00:00Z]

      {:ok, recurrences} = ICal.Recurrence.Generate.all(rule, dtstart)

      assert Enum.count(recurrences) == count
      [recurrence | _] = recurrences
      assert %{month: 4} = recurrence
    end

    test "every day in january for 3 years using BYMONTH and BYDAY" do
      dtstart = DateTime.new!(~D[1998-01-01], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics(
          "RRULE:FREQ=YEARLY;UNTIL=20000131T140000Z;BYMONTH=1;BYDAY=SU,MO,TU,WE,TH,FR,SA"
        )

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, dtstart) end,
          "every day in january for 3 years with yearly freq"
        )

      assert Enum.count(recurrences) == 93

      assert Enum.at(recurrences, 0) ==
               DateTime.new!(~D[1998-01-01], ~T[09:00:00], "America/New_York")

      assert Enum.at(recurrences, -1) ==
               DateTime.new!(~D[2000-01-31], ~T[09:00:00], "America/New_York")
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

      {:ok, recurrences} = ICal.Recurrence.Generate.all(rule, dtstart)

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

      {:ok, recurrences} = ICal.Recurrence.Generate.all(rule, dtstart)

      assert Enum.count(recurrences) == count
      [recurrence | _] = recurrences
      assert %{month: 4} = recurrence
    end

    test "by week number" do
      count = 22
      rule = %ICal.Recurrence{frequency: :yearly, count: count, by_week_number: [3, 17]}
      dtstart = ~U[2026-04-15 13:00:00Z]

      {:ok, recurrences} = ICal.Recurrence.Generate.all(rule, dtstart)

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

      {:ok, recurrences} = ICal.Recurrence.Generate.all(rule, dtstart)

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

      {:ok, recurrences} = ICal.Recurrence.Generate.all(rule, dtstart)

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

      {:ok, recurrences} = ICal.Recurrence.Generate.all(rule, dtstart)

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

  describe "Recurrence generation with daily frequence" do
    test "every day in january for 3 years using BYMONTH" do
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

    test "daily until December 24, 1997" do
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")
      rule = ICal.Recurrence.from_ics("RRULE:FREQ=DAILY;UNTIL=19971224T000000Z")

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, dtstart) end,
          "daily until December 24, 1997"
        )

      assert Enum.at(recurrences, 0) ==
               DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")

      # DST hits, and it is one hour earlier!
      assert Enum.at(recurrences, -1) ==
               DateTime.new!(~D[1997-12-23], ~T[08:00:00], "America/New_York")

      assert Enum.count(recurrences) == 113
    end

    test "every other day forever is rejected by all/2" do
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")
      rule = ICal.Recurrence.from_ics("RRULE:FREQ=DAILY;INTERVAL=2")

      assert {:error, :no_defined_limit, []} == ICal.Recurrence.Generate.all(rule, dtstart)
    end

    test "every other day forever works with a stream" do
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")
      rule = ICal.Recurrence.from_ics("RRULE:FREQ=DAILY;INTERVAL=2")
      count = 10

      expected = [
        DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-04], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-06], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-08], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-12], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-14], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-16], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-18], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-20], ~T[09:00:00], "America/New_York")
      ]

      recurrences =
        ICal.Recurrence.stream(rule, dtstart, [])
        |> Enum.take(count)

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    test "every 10 days, five times" do
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")
      rule = ICal.Recurrence.from_ics("RRULE:FREQ=DAILY;INTERVAL=10;COUNT=5")
      count = 10

      expected = [
        DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-12], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-22], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-02], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-12], ~T[09:00:00], "America/New_York")
      ]

      recurrences =
        ICal.Recurrence.stream(rule, dtstart, [])
        |> Enum.take(count)

      assert Enum.count(recurrences) == 5
      assert recurrences == expected
    end
  end

  describe "Recurrence generation with weekly frequency," do
    test "weekly for 10 weeks" do
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")
      rule = ICal.Recurrence.from_ics("RRULE:FREQ=WEEKLY;COUNT=10")

      {:ok, recurrences} =
        Helper.time(fn -> ICal.Recurrence.Generate.all(rule, dtstart) end, "weekly for 10 weeks")

      assert Enum.count(recurrences) == 10
      #        ==> (1997 9:00 AM EDT) September 2,9,16,23,30;October 7,14,21
      #            (1997 9:00 AM EST) October 28;November 4
    end

    test "weekly until a date" do
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")
      rule = ICal.Recurrence.from_ics("RRULE:FREQ=WEEKLY;UNTIL=19971224T000000Z")

      {:ok, recurrences} =
        Helper.time(fn -> ICal.Recurrence.Generate.all(rule, dtstart) end, "weekly for 10 weeks")

      assert Enum.count(recurrences) == 17
      assert Enum.at(recurrences, 0) == dtstart

      assert Enum.at(recurrences, -1) ==
               DateTime.new!(~D[1997-12-23], ~T[08:00:00], "America/New_York")
    end

    test "every other week, forever" do
      count = 5
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")
      rule = ICal.Recurrence.from_ics("RRULE:FREQ=WEEKLY;INTERVAL=2;WKST=SU")

      recurrences =
        Helper.time(
          fn -> ICal.Recurrence.stream(rule, dtstart, []) |> Enum.take(count) end,
          "every other week, forever"
        )

      assert Enum.count(recurrences) == count
      assert Enum.at(recurrences, 0) == dtstart

      assert Enum.at(recurrences, -1) ==
               DateTime.new!(~D[1997-10-28], ~T[08:00:00], "America/New_York")
    end

    test "five weeks of tuesdays and thursdays" do
      count = 10
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics("RRULE:FREQ=WEEKLY;UNTIL=19971007T000000Z;WKST=SU;BYDAY=TU,TH")

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, dtstart) end,
          "every other week, forever"
        )

      expected = [
        DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-04], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-09], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-11], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-16], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-18], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-23], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-25], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-30], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-02], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    test "every other week on Monday, Wednesday, and Friday until December
      24, 1997, starting on Monday, September 1, 1997" do
      count = 25
      dtstart = DateTime.new!(~D[1997-09-01], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics(
          "RRULE:FREQ=WEEKLY;INTERVAL=2;UNTIL=19971224T000000Z;WKST=SU;BYDAY=MO,WE,FR"
        )

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, dtstart) end,
          "every other week, Mo/We/Fr until Dec 24"
        )

      expected = [
        DateTime.new!(~D[1997-09-01], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-03], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-05], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-15], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-17], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-19], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-29], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-01], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-03], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-13], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-15], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-17], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-27], ~T[08:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-29], ~T[08:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-31], ~T[08:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-10], ~T[08:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-12], ~T[08:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-14], ~T[08:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-24], ~T[08:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-26], ~T[08:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-28], ~T[08:00:00], "America/New_York"),
        DateTime.new!(~D[1997-12-08], ~T[08:00:00], "America/New_York"),
        DateTime.new!(~D[1997-12-10], ~T[08:00:00], "America/New_York"),
        DateTime.new!(~D[1997-12-12], ~T[08:00:00], "America/New_York"),
        DateTime.new!(~D[1997-12-22], ~T[08:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    test "every other week on Tuesday and Thursday, for 8 occurrences" do
      count = 8
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics("RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=8;WKST=SU;BYDAY=TU,TH")

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, dtstart) end,
          "every other week, Mo/We/Fr until Dec 24"
        )

      expected = [
        DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-04], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-16], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-18], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-30], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-02], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-14], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-16], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    #   ==> (1997 9:00 AM EDT) September 5;October 3
    #            (1997 9:00 AM EST) November 7;December 5
    #            (1998 9:00 AM EST) January 2;February 6;March 6;April 3
    #            (1998 9:00 AM EDT) May 1;June 5
    test "monthly on the first Friday for 10 occurrences" do
      count = 10
      dtstart = DateTime.new!(~D[1997-09-05], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics("RRULE:FREQ=MONTHLY;COUNT=10;BYDAY=1FR")

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, dtstart) end,
          "every other week, Mo/We/Fr until Dec 24"
        )

      expected = [
        DateTime.new!(~D[1997-09-05], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-03], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-07], ~T[08:00:00], "America/New_York"),
        DateTime.new!(~D[1997-12-05], ~T[08:00:00], "America/New_York"),
        DateTime.new!(~D[1998-01-02], ~T[08:00:00], "America/New_York"),
        DateTime.new!(~D[1998-02-06], ~T[08:00:00], "America/New_York"),
        DateTime.new!(~D[1998-03-06], ~T[08:00:00], "America/New_York"),
        DateTime.new!(~D[1998-04-03], ~T[08:00:00], "America/New_York"),
        DateTime.new!(~D[1998-05-01], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-06-05], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end
  end
end
