defmodule ICal.RecurrenceTest do
  use ExUnit.Case

  alias ICal.Test.Fixtures
  alias ICal.Test.Helper

  doctest ICal.Recurrence

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

  describe "Recurrence generation with yearly frequence," do
    test "simple" do
      count = 5
      rule = %ICal.Recurrence{frequency: :yearly, count: count}
      dtstart = ~U[2026-04-15 13:00:00Z]

      {:ok, recurrences} = ICal.Recurrence.Generate.all(rule, start_date: dtstart)

      assert Enum.count(recurrences) == count
    end

    test "by month" do
      count = 5
      rule = %ICal.Recurrence{frequency: :yearly, count: count, by_month: [1, 4, 6]}
      dtstart = ~U[2026-04-15 13:00:00Z]

      {:ok, recurrences} = ICal.Recurrence.Generate.all(rule, start_date: dtstart)

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
          fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
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

      {:ok, recurrences} = ICal.Recurrence.Generate.all(rule, start_date: dtstart)

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

      {:ok, recurrences} = ICal.Recurrence.Generate.all(rule, start_date: dtstart)

      assert Enum.count(recurrences) == count
      [recurrence | _] = recurrences
      assert %{month: 4} = recurrence
    end

    test "by week number" do
      count = 22
      rule = %ICal.Recurrence{frequency: :yearly, count: count, by_week_number: [3, 17]}
      dtstart = ~U[2026-04-15 13:00:00Z]

      {:ok, recurrences} = ICal.Recurrence.Generate.all(rule, start_date: dtstart)

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

      {:ok, recurrences} = ICal.Recurrence.Generate.all(rule, start_date: dtstart)

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

      {:ok, recurrences} = ICal.Recurrence.Generate.all(rule, start_date: dtstart)

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

      {:ok, recurrences} = ICal.Recurrence.Generate.all(rule, start_date: dtstart)

      assert Enum.count(recurrences) == count

      assert [
               ~U[2027-01-15 13:00:00Z],
               ~U[2028-01-15 13:00:00Z],
               ~U[2029-01-15 13:00:00Z],
               ~U[2030-01-15 13:00:00Z],
               ~U[2031-01-15 13:00:00Z]
             ] == recurrences
    end

    test "in June and July for 10 occurrences" do
      count = 10
      dtstart = DateTime.new!(~D[1997-06-10], ~T[09:00:00], "America/New_York")

      rule = ICal.Recurrence.from_ics("RRULE:FREQ=YEARLY;COUNT=10;BYMONTH=6,7")

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
          "in June and July for 10 occurrences"
        )

      expected = [
        DateTime.new!(~D[1997-06-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-07-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-06-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-07-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1999-06-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1999-07-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2000-06-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2000-07-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2001-06-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2001-07-10], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count

      assert recurrences == expected
    end

    test "every other year on January, February, and March for 10 occurences" do
      count = 10
      dtstart = DateTime.new!(~D[1997-03-10], ~T[09:00:00], "America/New_York")

      rule = ICal.Recurrence.from_ics("RRULE:FREQ=YEARLY;INTERVAL=2;COUNT=10;BYMONTH=1,2,3")

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
          "every other year on January, February, and March for 10 occurences"
        )

      expected = [
        DateTime.new!(~D[1997-03-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1999-01-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1999-02-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1999-03-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2001-01-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2001-02-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2001-03-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2003-01-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2003-02-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2003-03-10], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count

      assert recurrences == expected
    end

    test "every third year on the 1st, 100th, and 200th day for 10 occurences" do
      count = 10
      dtstart = DateTime.new!(~D[1997-01-01], ~T[09:00:00], "America/New_York")

      rule = ICal.Recurrence.from_ics("RRULE:FREQ=YEARLY;INTERVAL=3;COUNT=10;BYYEARDAY=1,100,200")

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
          "every third year on the 1st, 100th, and 200th day for 10 occurences"
        )

      expected = [
        DateTime.new!(~D[1997-01-01], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-04-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-07-19], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2000-01-01], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2000-04-09], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2000-07-18], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2003-01-01], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2003-04-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2003-07-19], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2006-01-01], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count

      assert recurrences == expected
    end

    test "every 20th Monday of the year" do
      count = 3
      dtstart = DateTime.new!(~D[1997-05-19], ~T[09:00:00], "America/New_York")

      rule = ICal.Recurrence.from_ics("RRULE:FREQ=YEARLY;BYDAY=20MO")

      recurrences =
        Helper.time(
          fn -> ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.take(count) end,
          "every 20th Monday of the year"
        )

      expected = [
        DateTime.new!(~D[1997-05-19], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-05-18], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1999-05-17], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count

      assert recurrences == expected
    end

    test "every 2nd-to-last Monday of the year" do
      count = 3
      dtstart = DateTime.new!(~D[1997-12-22], ~T[09:00:00], "America/New_York")

      rule = ICal.Recurrence.from_ics("RRULE:FREQ=YEARLY;BYDAY=-2MO")

      recurrences =
        Helper.time(
          fn -> ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.take(count) end,
          "every 2nd-to-last Monday of the year"
        )

      expected = [
        DateTime.new!(~D[1997-12-22], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-12-21], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1999-12-20], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count

      assert recurrences == expected
    end

    test "Monday of week number 20 (where the default start of the week is Monday" do
      count = 3
      dtstart = DateTime.new!(~D[1997-05-12], ~T[09:00:00], "America/New_York")

      rule = ICal.Recurrence.from_ics("RRULE:FREQ=YEARLY;BYWEEKNO=20;BYDAY=MO")

      recurrences =
        Helper.time(
          fn -> ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.take(count) end,
          "Monday of week number 20 (where the default start of the week is Monday"
        )

      expected = [
        DateTime.new!(~D[1997-05-12], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-05-11], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1999-05-17], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count

      assert recurrences == expected
    end

    test "every Thursday in March" do
      count = 7
      dtstart = DateTime.new!(~D[1997-03-13], ~T[09:00:00], "America/New_York")

      rule = ICal.Recurrence.from_ics("RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=TH")

      recurrences =
        Helper.time(
          fn -> ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.take(count) end,
          "every Thursday in March"
        )

      expected = [
        DateTime.new!(~D[1997-03-13], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-03-20], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-03-27], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-03-05], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-03-12], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-03-19], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-03-26], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count

      assert recurrences == expected
    end

    test "every Thursday, but only during June, July, and August" do
      count = 14
      dtstart = DateTime.new!(~D[1997-06-05], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics("RRULE:FREQ=YEARLY;BYDAY=TH;BYMONTH=6,7,8")

      recurrences =
        Helper.time(
          fn -> ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.take(count) end,
          "every Thursday, but only during June, July, and August"
        )

      expected = [
        DateTime.new!(~D[1997-06-05], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-06-12], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-06-19], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-06-26], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-07-03], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-07-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-07-17], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-07-24], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-07-31], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-08-07], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-08-14], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-08-21], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-08-28], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-06-04], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count

      assert recurrences == expected
    end

    test "every 4 years, the first Tuesday after a Monday in November" do
      count = 3
      dtstart = DateTime.new!(~D[1996-11-05], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics(
          "RRULE:FREQ=YEARLY;INTERVAL=4;BYMONTH=11;BYDAY=TU;BYMONTHDAY=2,3,4,5,6,7,8"
        )

      recurrences =
        Helper.time(
          fn -> ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.take(count) end,
          "every 4 years, the first Tuesday after a Monday in November"
        )

      expected = [
        DateTime.new!(~D[1996-11-05], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2000-11-07], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2004-11-02], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count

      assert recurrences == expected
    end
  end

  describe "Recurrence generation with daily frequence," do
    test "every day in january for 3 years using BYMONTH" do
      dtstart = DateTime.new!(~D[1998-01-31], ~T[09:00:00], "America/New_York")
      rule = ICal.Recurrence.from_ics("RRULE:FREQ=DAILY;UNTIL=20000131T140000Z;BYMONTH=1")

      Helper.time(
        fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
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
        fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
        "every 10th and 31st in january for 3 years"
      )
    end

    test "every Tuesday and Thursday in january for 3 years" do
      dtstart = DateTime.new!(~D[2026-01-31], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics("RRULE:FREQ=DAILY;UNTIL=20280131T140000Z;BYMONTH=1;BYDAY=TH,TU")

      Helper.time(
        fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
        "every 10th and 31st in january for 3 years"
      )
    end

    test "daily until December 24, 1997" do
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")
      rule = ICal.Recurrence.from_ics("RRULE:FREQ=DAILY;UNTIL=19971224T000000Z")

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
          "daily until December 24, 1997"
        )

      assert Enum.at(recurrences, 0) ==
               DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")

      # DST hits, and it is one hour earlier!
      assert Enum.at(recurrences, -1) ==
               DateTime.new!(~D[1997-12-23], ~T[09:00:00], "America/New_York")

      assert Enum.count(recurrences) == 113
    end

    test "every other day forever is rejected by all/2" do
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")
      rule = ICal.Recurrence.from_ics("RRULE:FREQ=DAILY;INTERVAL=2")

      assert {:error, :no_defined_limit, []} ==
               ICal.Recurrence.Generate.all(rule, start_date: dtstart)
    end

    test "recurrenct termination is correctly noted" do
      rule = ICal.Recurrence.from_ics("RRULE:FREQ=DAILY;INTERVAL=2")
      refute ICal.Recurrence.terminates?(rule)

      rule = ICal.Recurrence.from_ics("RRULE:FREQ=DAILY;INTERVAL=2;COUNT=10")
      assert ICal.Recurrence.terminates?(rule)
      rule = ICal.Recurrence.from_ics("RRULE:FREQ=DAILY;INTERVAL=2;UNTIL=19971224T000000Z")
      assert ICal.Recurrence.terminates?(rule)
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
        ICal.Recurrence.stream(rule, start_date: dtstart)
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
        ICal.Recurrence.stream(rule, start_date: dtstart)
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
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
          "weekly for 10 weeks"
        )

      assert Enum.count(recurrences) == 10
      #        ==> (1997 9:00 AM EDT) September 2,9,16,23,30;October 7,14,21
      #            (1997 9:00 AM EST) October 28;November 4
    end

    test "weekly until a date" do
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")
      rule = ICal.Recurrence.from_ics("RRULE:FREQ=WEEKLY;UNTIL=19971224T000000Z")

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
          "weekly for 10 weeks"
        )

      assert Enum.count(recurrences) == 17
      assert Enum.at(recurrences, 0) == dtstart

      assert Enum.at(recurrences, -1) ==
               DateTime.new!(~D[1997-12-23], ~T[09:00:00], "America/New_York")
    end

    test "every other week, forever" do
      count = 5
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")
      rule = ICal.Recurrence.from_ics("RRULE:FREQ=WEEKLY;INTERVAL=2;WKST=SU")

      recurrences =
        Helper.time(
          fn -> ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.take(count) end,
          "every other week, forever"
        )

      assert Enum.count(recurrences) == count
      assert Enum.at(recurrences, 0) == dtstart

      assert Enum.at(recurrences, -1) ==
               DateTime.new!(~D[1997-10-28], ~T[09:00:00], "America/New_York")
    end

    test "five weeks of tuesdays and thursdays" do
      count = 10
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics("RRULE:FREQ=WEEKLY;UNTIL=19971007T000000Z;WKST=SU;BYDAY=TU,TH")

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
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

    test "every other week on Monday, Wednesday, and Friday until December 24, 1997" do
      count = 25
      dtstart = DateTime.new!(~D[1997-09-01], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics(
          "RRULE:FREQ=WEEKLY;INTERVAL=2;UNTIL=19971224T000000Z;WKST=SU;BYDAY=MO,WE,FR"
        )

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
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
        DateTime.new!(~D[1997-10-27], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-29], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-31], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-12], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-14], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-24], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-26], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-28], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-12-08], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-12-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-12-12], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-12-22], ~T[09:00:00], "America/New_York")
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
          fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
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

    test "WKST variance -> days generated with MO WKST" do
      count = 4
      dtstart = DateTime.new!(~D[1997-08-05], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics("RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=MO")

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
          "WKST variance -> days generated with MO WKST"
        )

      expected = [
        DateTime.new!(~D[1997-08-05], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-08-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-08-19], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-08-24], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    test "WKST variance -> days generated with SU WKST" do
      count = 4
      dtstart = DateTime.new!(~D[1997-08-05], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics("RRULE:FREQ=WEEKLY;INTERVAL=2;COUNT=4;BYDAY=TU,SU;WKST=SU")

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
          "example where the days generated makes a difference because of WKST"
        )

      expected = [
        DateTime.new!(~D[1997-08-05], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-08-17], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-08-19], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-08-31], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end
  end

  describe "Recurrence generation with monthly frequency," do
    test "on the first Friday for 10 occurrences" do
      count = 10
      dtstart = DateTime.new!(~D[1997-09-05], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics("RRULE:FREQ=MONTHLY;COUNT=10;BYDAY=1FR")

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
          "monthly on the first Friday for 10 occurrences"
        )

      expected = [
        DateTime.new!(~D[1997-09-05], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-03], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-07], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-12-05], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-01-02], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-02-06], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-03-06], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-04-03], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-05-01], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-06-05], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    test "on the first Friday until December 24, 1997" do
      count = 4
      dtstart = DateTime.new!(~D[1997-09-05], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics("RRULE:FREQ=MONTHLY;UNTIL=19971224T000000Z;BYDAY=1FR")

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
          "monthly on the first Friday until December 24, 1997"
        )

      expected = [
        DateTime.new!(~D[1997-09-05], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-03], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-07], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-12-05], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    test "every other month on the first and last Sunday of the month for 10 occurences" do
      count = 10
      dtstart = DateTime.new!(~D[1997-09-07], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics("RRULE:FREQ=MONTHLY;INTERVAL=2;COUNT=10;BYDAY=1SU,-1SU")

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
          "every other month on the first and last Sunday of the month for 10 occurences"
        )

      expected = [
        DateTime.new!(~D[1997-09-07], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-28], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-02], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-30], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-01-04], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-01-25], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-03-01], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-03-29], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-05-03], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-05-31], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    test "on the second-to-last Monday of the month for 6 months" do
      count = 6
      dtstart = DateTime.new!(~D[1997-09-22], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics("RRULE:FREQ=MONTHLY;COUNT=6;BYDAY=-2MO")

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
          "monthly on the second-to-last Monday of the month for 6 months"
        )

      expected = [
        DateTime.new!(~D[1997-09-22], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-20], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-17], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-12-22], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-01-19], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-02-16], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    test "on the third-to-the-last day of the month" do
      count = 6
      dtstart = DateTime.new!(~D[1997-09-28], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics("RRULE:FREQ=MONTHLY;BYMONTHDAY=-3")

      recurrences =
        Helper.time(
          fn -> ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.take(count) end,
          "on the third-to-the-last day of the month"
        )

      expected = [
        DateTime.new!(~D[1997-09-28], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-29], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-28], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-12-29], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-01-29], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-02-26], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    test "2nd and 15th of the month for 10 occurrences" do
      count = 10
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics("RRULE:FREQ=MONTHLY;COUNT=10;BYMONTHDAY=2,15")

      recurrences =
        Helper.time(
          fn -> ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.to_list() end,
          "2nd and 15th of the month for 10 occurrences"
        )

      expected = [
        DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-15], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-02], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-15], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-02], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-15], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-12-02], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-12-15], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-01-02], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-01-15], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    test "first and last day of the month for 10 occurrencess" do
      count = 10
      dtstart = DateTime.new!(~D[1997-09-30], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics("RRULE:FREQ=MONTHLY;COUNT=10;BYMONTHDAY=1,-1")

      recurrences =
        Helper.time(
          fn -> ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.to_list() end,
          "first and last day of the month for 10 occurrencess"
        )

      expected = [
        DateTime.new!(~D[1997-09-30], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-01], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-31], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-01], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-30], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-12-01], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-12-31], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-01-01], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-01-31], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-02-01], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    test "every 18 months on the 10th thru 15th of the month for 10 occurrencess" do
      count = 10
      dtstart = DateTime.new!(~D[1997-09-10], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics(
          "RRULE:FREQ=MONTHLY;INTERVAL=18;COUNT=10;BYMONTHDAY=10,11,12,13,14,15"
        )

      recurrences =
        Helper.time(
          fn -> ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.to_list() end,
          "every 18 months on the 10th thru 15th of the month for 10 occurrencess"
        )

      expected = [
        DateTime.new!(~D[1997-09-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-11], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-12], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-13], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-14], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-15], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1999-03-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1999-03-11], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1999-03-12], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1999-03-13], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    test "every Tuesday, every other month" do
      count = 13
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")

      rule = ICal.Recurrence.from_ics("RRULE:FREQ=MONTHLY;INTERVAL=2;BYDAY=TU")

      recurrences =
        Helper.time(
          fn -> ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.take(count) end,
          "every Tuesday, every other month"
        )

      expected = [
        DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-09], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-16], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-23], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-30], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-04], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-11], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-18], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-25], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-01-06], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-01-13], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-01-20], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-01-27], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    test "every Friday the 13th" do
      count = 5
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")

      rule = ICal.Recurrence.from_ics("RRULE:FREQ=MONTHLY;BYDAY=FR;BYMONTHDAY=13")

      recurrences =
        Helper.time(
          fn ->
            ICal.Recurrence.stream(rule, start_date: dtstart, exclude_recurrences: [dtstart])
            |> Enum.take(count)
          end,
          "every Friday the 13th"
        )

      expected = [
        DateTime.new!(~D[1998-02-13], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-03-13], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-11-13], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1999-08-13], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2000-10-13], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    test "first Saturday that follows the first Sunday of the month" do
      count = 7
      dtstart = DateTime.new!(~D[1997-09-13], ~T[09:00:00], "America/New_York")

      rule = ICal.Recurrence.from_ics("RRULE:FREQ=MONTHLY;BYDAY=SA;BYMONTHDAY=7,8,9,10,11,12,13")

      recurrences =
        Helper.time(
          fn -> ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.take(count) end,
          "first Saturday that follows the first Sunday of the month"
        )

      expected = [
        DateTime.new!(~D[1997-09-13], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-11], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-08], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-12-13], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-01-10], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-02-07], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-03-07], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    test "third instance into the month of one of Tuesday, Wednesday, or Thursday for the next 3 months" do
      count = 3
      dtstart = DateTime.new!(~D[1997-09-04], ~T[09:00:00], "America/New_York")

      rule = ICal.Recurrence.from_ics("RRULE:FREQ=MONTHLY;COUNT=3;BYDAY=TU,WE,TH;BYSETPOS=3")

      recurrences =
        Helper.time(
          fn -> ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.to_list() end,
          "third instance into the month of one of Tuesday, Wednesday, or Thursday for the next 3 months"
        )

      expected = [
        DateTime.new!(~D[1997-09-04], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-07], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-06], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    test "second-to-last weekday of the month" do
      count = 7
      dtstart = DateTime.new!(~D[1997-09-29], ~T[09:00:00], "America/New_York")

      rule = ICal.Recurrence.from_ics("RRULE:FREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-2")

      recurrences =
        Helper.time(
          fn -> ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.take(count) end,
          "second-to-last weekday of the month"
        )

      expected = [
        DateTime.new!(~D[1997-09-29], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-10-30], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-11-27], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-12-30], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-01-29], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-02-26], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1998-03-30], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    test "an invalid date (February 30) is ignored" do
      count = 5
      dtstart = DateTime.new!(~D[2007-01-15], ~T[09:00:00], "America/New_York")

      rule = ICal.Recurrence.from_ics("RRULE:FREQ=MONTHLY;BYMONTHDAY=15,30;COUNT=5")

      recurrences =
        Helper.time(
          fn -> ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.take(count) end,
          "second-to-last weekday of the month"
        )

      expected = [
        DateTime.new!(~D[2007-01-15], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2007-01-30], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2007-02-15], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2007-03-15], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[2007-03-30], ~T[09:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end
  end

  describe "Recurrence generation with time components," do
    test "every 3 hours from 9:00 AM to 5:00 PM on a specific day" do
      count = 3
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics("RRULE:FREQ=HOURLY;INTERVAL=3;UNTIL=19970902T170000Z")

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
          "every 3 hours from 9:00 AM to 5:00 PM on a specific day"
        )

      expected = [
        DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-02], ~T[12:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-02], ~T[15:00:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    test "every 15 minutes for 6 occurrences" do
      count = 6
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics("RRULE:FREQ=MINUTELY;INTERVAL=15;COUNT=6")

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
          "every 15 minutes for 6 occurrences"
        )

      expected = [
        DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-02], ~T[09:15:00], "America/New_York"),
        DateTime.new!(~D[1997-09-02], ~T[09:30:00], "America/New_York"),
        DateTime.new!(~D[1997-09-02], ~T[09:45:00], "America/New_York"),
        DateTime.new!(~D[1997-09-02], ~T[10:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-02], ~T[10:15:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count
      assert recurrences == expected
    end

    test "every hour and a half for 4 occurrences" do
      count = 4
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics("RRULE:FREQ=MINUTELY;INTERVAL=90;COUNT=4")

      {:ok, recurrences} =
        Helper.time(
          fn -> ICal.Recurrence.Generate.all(rule, start_date: dtstart) end,
          "every hour and a half for 4 occurrences"
        )

      expected = [
        DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-02], ~T[10:30:00], "America/New_York"),
        DateTime.new!(~D[1997-09-02], ~T[12:00:00], "America/New_York"),
        DateTime.new!(~D[1997-09-02], ~T[13:30:00], "America/New_York")
      ]

      assert Enum.count(recurrences) == count

      assert recurrences == expected
    end

    test "every 20 minutes from 9:00 AM to 4:40 PM every day" do
      count = 40
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")

      rule =
        ICal.Recurrence.from_ics(
          "RRULE:FREQ=DAILY;BYHOUR=9,10,11,12,13,14,15,16;BYMINUTE=0,20,40"
        )

      recurrences =
        Helper.time(
          fn -> ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.take(count) end,
          "every 20 minutes from 9:00 AM to 4:40 PM every day"
        )

      assert Enum.count(recurrences) == count

      assert [
               DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York"),
               DateTime.new!(~D[1997-09-02], ~T[09:20:00], "America/New_York"),
               DateTime.new!(~D[1997-09-02], ~T[09:40:00], "America/New_York"),
               DateTime.new!(~D[1997-09-02], ~T[10:00:00], "America/New_York")
             ] == Enum.slice(recurrences, 0, 4)

      assert [
               DateTime.new!(~D[1997-09-02], ~T[16:40:00], "America/New_York"),
               DateTime.new!(~D[1997-09-03], ~T[09:00:00], "America/New_York")
             ] == Enum.slice(recurrences, 23, 2)

      assert DateTime.new!(~D[1997-09-03], ~T[14:00:00], "America/New_York") ==
               Enum.at(recurrences, -1)
    end

    test "every 25 seconds from 09:00" do
      count = 4
      dtstart = DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York")

      rule = ICal.Recurrence.from_ics("RRULE:FREQ=SECONDLY;INTERVAL=25")

      recurrences =
        Helper.time(
          fn -> ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.take(count) end,
          "every 25 seconds from 09:00"
        )

      assert Enum.count(recurrences) == count

      assert [
               DateTime.new!(~D[1997-09-02], ~T[09:00:00], "America/New_York"),
               DateTime.new!(~D[1997-09-02], ~T[09:00:25], "America/New_York"),
               DateTime.new!(~D[1997-09-02], ~T[09:00:50], "America/New_York"),
               DateTime.new!(~D[1997-09-02], ~T[09:01:15], "America/New_York")
             ] == recurrences
    end
  end
end
