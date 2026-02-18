defmodule ICal.RecurrenceTest do
  use ExUnit.Case

  alias ICal.Test.Fixtures
  alias ICal.Test.Helper

  test "ICalender.to_ics/1 with rrule" do
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

  test "Recurrence.from_event/1 returns nil when there are no rrules" do
    assert nil == ICal.Deserialize.Recurrence.from_event(%ICal.Event{})
  end

  test "Recurrence.from_event/1 returns the recurrence struct when there one already available" do
    assert %ICal.Recurrence{} ===
             ICal.Deserialize.Recurrence.from_event(%ICal.Event{rrule: %ICal.Recurrence{}})
  end

  test "Recurrence.from_event/1 turns a params map into a recurrence struct" do
    assert %ICal.Recurrence{frequency: :daily} ===
             ICal.Deserialize.Recurrence.from_event(%ICal.Event{rrule: %{"FREQ" => "DAILY"}})
  end

  test "Recurrence deserialization ignores bad WKST values" do
    event = %ICal.Event{rrule: %{"FREQ" => "DAILY", "WKST" => "NO"}}

    assert %ICal.Recurrence{frequency: :daily, weekday: nil} ===
             ICal.Deserialize.Recurrence.from_event(event)
  end

  test "Recurrence deserialization clamps time values" do
    event = %ICal.Event{
      rrule: %{
        "FREQ" => "DAILY",
        "BYSECOND" => "-1,-,0,1,10,50,59,60,70",
        "BYMINUTE" => "-1,-,0,1,10,50,59,60,70",
        "BYHOUR" => "-1,-,0,1,6,12,23,24"
      }
    }

    assert %ICal.Recurrence{
             frequency: :daily,
             by_second: [0, 1, 10, 50, 59],
             by_minute: [0, 1, 10, 50, 59],
             by_hour: [0, 1, 6, 12, 23]
           } === ICal.Deserialize.Recurrence.from_event(event)
  end

  test "Recurrence deserialization clamps day/week/month values" do
    event = %ICal.Event{
      rrule: %{
        "FREQ" => "DAILY",
        "BYWEEKNO" => "-54,-53,-1,0,a,1,25,2,53,54",
        "BYMONTHDAY" => "-32,-31,a,-1,1,31,32",
        "BYMONTH" => "0,1,12,a,13",
        "BYYEARDAY" => "-367,-366,-1,0,a,,1,366,367,garbage",
        "BYSETPOS" => "-367,-366,-1,0,a,,1,366,367"
      }
    }

    assert %ICal.Recurrence{
             frequency: :daily,
             by_week_number: [-53, -1, 1, 25, 2, 53],
             by_month_day: [-31, -1, 1, 31],
             by_month: [1, 12],
             by_year_day: [-366, -1, 1, 366],
             by_set_position: [-366, -1, 1, 366]
           } === ICal.Deserialize.Recurrence.from_event(event)
  end

  test "Recurrence deserialization ignores garbage in count and interval" do
    event = %ICal.Event{
      rrule: %{
        "FREQ" => "DAILY",
        "COUNT" => "GARBAGE",
        "INTERVAL" => ""
      }
    }

    assert %ICal.Recurrence{
             frequency: :daily,
             count: nil,
             interval: 1
           } === ICal.Deserialize.Recurrence.from_event(event)
  end

  test "Recurrence de/serializes weekday abbreviations corrrectly" do
    event = %ICal.Event{
      rrule: %{"FREQ" => "DAILY", "BYDAY" => "-1SU,SU,1MO,-1TU,+2WE,TH,FR,SA,GA,GARBAGE,,0,-1"}
    }

    recurrence = %ICal.Recurrence{
      frequency: :daily,
      by_day: [
        {-1, :sunday},
        {nil, :sunday},
        {1, :monday},
        {-1, :tuesday},
        {2, :wednesday},
        {nil, :thursday},
        {nil, :friday},
        {nil, :saturday}
      ]
    }

    assert recurrence === ICal.Deserialize.Recurrence.from_event(event)

    assert [
             [
               "RRULE:FREQ=",
               "DAILY",
               [
                 59,
                 "INTERVAL",
                 61,
                 "1",
                 59,
                 "BYDAY",
                 61,
                 [
                   ["-1", "SU"],
                   ["", "SU"],
                   ["1", "MO"],
                   ["-1", "TU"],
                   ["2", "WE"],
                   ["", "TH"],
                   ["", "FR"],
                   ["", "SA"]
                 ]
               ],
               10
             ]
           ] == ICal.Serialize.Recurrence.to_ics(recurrence, [])
  end

  test "Recurrence serialization ignores anything that isn't a recurrence" do
    assert [] == ICal.Serialize.Recurrence.to_ics(nil, [])
    assert [] == ICal.Serialize.Recurrence.to_ics(%{}, [])
    assert [] == ICal.Serialize.Recurrence.to_ics(%{"FREQ" => "DAILY"}, [])
    assert [] == ICal.Serialize.Recurrence.to_ics("", [])
    assert [] == ICal.Serialize.Recurrence.to_ics(100, [])
  end

  test "Recurrence deserialization parses values of frequency corrrectly" do
    event = %ICal.Event{rrule: %{"FREQ" => "DAILY"}}
    assert %ICal.Recurrence{frequency: :daily} === ICal.Deserialize.Recurrence.from_event(event)

    event = %ICal.Event{rrule: %{"FREQ" => "WEEKLY"}}
    assert %ICal.Recurrence{frequency: :weekly} === ICal.Deserialize.Recurrence.from_event(event)

    event = %ICal.Event{rrule: %{"FREQ" => "MONTHLY"}}
    assert %ICal.Recurrence{frequency: :monthly} === ICal.Deserialize.Recurrence.from_event(event)

    event = %ICal.Event{rrule: %{"FREQ" => "YEARLY"}}
    assert %ICal.Recurrence{frequency: :yearly} === ICal.Deserialize.Recurrence.from_event(event)

    event = %ICal.Event{rrule: %{"FREQ" => "HOURLY"}}
    assert %ICal.Recurrence{frequency: :hourly} === ICal.Deserialize.Recurrence.from_event(event)

    event = %ICal.Event{rrule: %{"FREQ" => "MINUTELY"}}

    assert %ICal.Recurrence{frequency: :minutely} ===
             ICal.Deserialize.Recurrence.from_event(event)

    event = %ICal.Event{rrule: %{"FREQ" => "SECONDLY"}}

    assert %ICal.Recurrence{frequency: :secondly} ===
             ICal.Deserialize.Recurrence.from_event(event)

    event = %ICal.Event{rrule: %{"FREQ" => "GARBAGE"}}
    assert nil === ICal.Deserialize.Recurrence.from_event(event)
  end
end
