defmodule ICal.RecurrenceTest do
  use ExUnit.Case

  alias ICal.Test.Helper

  test "daily reccuring event with until" do
    events =
      Helper.test_data("recurrance_daily_until")
      |> ICal.from_ics()
      |> Map.get(:events)
      |> Enum.map(fn event ->
        recurrences =
          ICal.Recurrence.get_recurrences(event)
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
          ICal.Recurrence.get_recurrences(event)
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
          ICal.Recurrence.get_recurrences(event)
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
          ICal.Recurrence.get_recurrences(event)
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
          ICal.Recurrence.get_recurrences(event)
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
