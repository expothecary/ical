defmodule ICal.EventTest do
  use ExUnit.Case
  use ICal.Test.Helper
  alias ICal.Event
  alias ICal.Test.Fixtures

  test "ICal.to_ics/1 of event" do
    expected = """
    BEGIN:VEVENT
    DTSTAMP:20151224T084500Z
    END:VEVENT
    """

    %Event{dtstamp: ~U[2015-12-24 08:45:00Z]}
    |> ICal.Serialize.Event.component()
    |> assert_fully_contains(expected)
  end

  test "ICal.to_ics/1 with some attributes" do
    expected = Helper.test_data("serialized_event")

    Fixtures.one_event(:serialize)
    |> ICal.Serialize.Event.component()
    |> assert_fully_contains(expected)
  end

  test "ICal.to_ics/1 with date start and end" do
    expected = """
    BEGIN:VEVENT
    DTEND;VALUE=DATE:20151224
    DTSTAMP:20151224T084500Z
    DTSTART;VALUE=DATE:20151224
    END:VEVENT
    """

    %Event{
      dtstart: ~D[2015-12-24],
      dtend: ~D[2015-12-24],
      dtstamp: ~U[2015-12-24 08:45:00Z]
    }
    |> ICal.Serialize.Event.component()
    |> assert_fully_contains(expected)
  end

  test "ICal.to_ics/1 with datetime start and end" do
    expected = """
    BEGIN:VEVENT
    DTEND:20151224T084500Z
    DTSTAMP:20151224T084500Z
    DTSTART:20151224T083000Z
    END:VEVENT
    """

    %Event{
      dtstart: ~U[2015-12-24 08:30:00Z],
      dtend: ~U[2015-12-24 08:45:00Z],
      dtstamp: ~U[2015-12-24 08:45:00Z]
    }
    |> ICal.Serialize.Event.component()
    |> assert_fully_contains(expected)
  end

  test "Icalender.to_ics/1 with default value for DTSTAMP" do
    expected = """
    BEGIN:VEVENT
    DESCRIPTION:Let's go see Star Wars\\, and have fun.
    DTEND:20151224T084500Z
    DTSTAMP:#{ICal.Serialize.value(DateTime.utc_now())}
    DTSTART:20151224T083000Z
    SUMMARY:Film with Amy and Adam
    END:VEVENT
    """

    %ICal.Event{
      summary: "Film with Amy and Adam",
      dtstart: ~U[2015-12-24 08:30:00Z],
      dtend: ~U[2015-12-24 08:45:00Z],
      description: "Let's go see Star Wars, and have fun."
    }
    |> ICal.Serialize.Event.component()
    |> assert_fully_contains(expected)
  end

  test "ICal.to_ics/1 with datetime with timezone" do
    expected = """
    BEGIN:VEVENT
    DTEND;TZID=America/Chicago:20151224T084500
    DTSTAMP:20151224T084500Z
    DTSTART;TZID=America/Chicago:20151224T083000
    END:VEVENT
    """

    dtstart = DateTime.new!(~D[2015-12-24], ~T[08:30:00], "America/Chicago")

    dtend = DateTime.new!(~D[2015-12-24], ~T[08:45:00], "America/Chicago")

    %Event{
      dtstart: dtstart,
      dtend: dtend,
      dtstamp: ~U[2015-12-24 08:45:00Z]
    }
    |> ICal.Serialize.Event.component()
    |> assert_fully_contains(expected)
  end

  test "ICal.to_ics/1 does not damage url in description" do
    expected = """
    BEGIN:VEVENT
    DESCRIPTION:See this link http://example.com/pub/calendars/jsmith/mytime.ics
    DTSTAMP:20151224T084500Z
    SUMMARY:Going fishing
    END:VEVENT
    """

    %Event{
      summary: "Going fishing",
      description:
        "See this link http://example.com/pub" <>
          "/calendars/jsmith/mytime.ics",
      dtstamp: ~U[2015-12-24 08:45:00Z]
    }
    |> ICal.Serialize.Event.component()
    |> assert_fully_contains(expected)
  end

  test "ICal.to_ics/1 with url" do
    expected = """
    BEGIN:VEVENT
    DTSTAMP:20151224T084500Z
    URL:http://example.com/pub/calendars/jsmith/mytime.ics
    END:VEVENT
    """

    %Event{
      url: "http://example.com/pub/calendars/jsmith/mytime.ics",
      dtstamp: ~U[2015-12-24 08:45:00Z]
    }
    |> ICal.Serialize.Event.component()
    |> assert_fully_contains(expected)
  end

  test "ICal.to_ics/1 with integer UID" do
    expected = """
    BEGIN:VEVENT
    DTSTAMP:20151224T084500Z
    UID:815
    END:VEVENT
    """

    %Event{
      uid: 815,
      dtstamp: ~U[2015-12-24 08:45:00Z]
    }
    |> ICal.Serialize.Event.component()
    |> assert_fully_contains(expected)
  end

  test "ICal.to_ics/1 with string UID" do
    expected = """
    BEGIN:VEVENT
    DTSTAMP:20151224T084500Z
    UID:0815
    END:VEVENT
    """

    %Event{
      uid: "0815",
      dtstamp: ~U[2015-12-24 08:45:00Z]
    }
    |> ICal.Serialize.Event.component()
    |> assert_fully_contains(expected)
  end

  test "ICal.to_ics/1 with geo" do
    expected = """
    BEGIN:VEVENT
    DTSTAMP:20151224T084500Z
    GEO:43.6978819;-79.3810277
    END:VEVENT
    """

    %Event{
      geo: {43.6978819, -79.3810277},
      dtstamp: ~U[2015-12-24 08:45:00Z]
    }
    |> ICal.Serialize.Event.component()
    |> assert_fully_contains(expected)
  end

  test "ICal.to_ics/1 with categories" do
    expected = """
    BEGIN:VEVENT
    CATEGORIES:Fishing,Nature,Sport
    DTSTAMP:20151224T084500Z
    END:VEVENT
    """

    %Event{
      categories: ["Fishing", "Nature", "Sport"],
      dtstamp: ~U[2015-12-24 08:45:00Z]
    }
    |> ICal.Serialize.Event.component()
    |> assert_fully_contains(expected)
  end

  test "ICal.to_ics/1 with status" do
    expected = """
    BEGIN:VEVENT
    DTSTAMP:20151224T084500Z
    STATUS:TENTATIVE
    END:VEVENT
    """

    %Event{
      status: :tentative,
      dtstamp: ~U[2015-12-24 08:45:00Z]
    }
    |> ICal.Serialize.Event.component()
    |> assert_fully_contains(expected)
  end

  test "ICal.to_ics/1 with class" do
    expected = """
    BEGIN:VEVENT
    CLASS:PRIVATE
    DTSTAMP:20151224T084500Z
    END:VEVENT
    """

    %Event{
      class: :private,
      dtstamp: ~U[2015-12-24 08:45:00Z]
    }
    |> ICal.Serialize.Event.component()
    |> assert_fully_contains(expected)
  end

  test "Serializing statuses" do
    expected = Helper.test_data("status_serialized")

    Fixtures.statuses(:serialize)
    |> ICal.to_ics()
    |> assert_fully_contains(expected)
  end

  test "Serializing rdates" do
    expected = Helper.test_data("rdates_serialized")

    Fixtures.rdates()
    |> ICal.to_ics()
    |> assert_fully_contains(expected)
  end

  test "encode attendees" do
    expected = Helper.test_data("attendees_serialized")

    Fixtures.attendees()
    |> ICal.to_ics()
    |> assert_fully_contains(expected)
  end

  test "next_alarm/1 for an event with recurrences" do
    event_with_alarm = Fixtures.one_event(:one_alarm)
    expected_next_alarm = Fixtures.alarm(:audio)

    actual_next_alarms = ICal.Alarm.next_alarms(event_with_alarm)
    assert [{%DateTime{}, ^expected_next_alarm}] = actual_next_alarms
  end

  test "next_alarm/1 for an event with no alarm" do
    event_without_alarm = Fixtures.one_event(:deserialize)

    actual_next_alarms = ICal.Alarm.next_alarms(event_without_alarm)
    assert [] == actual_next_alarms
  end

  test "next_alarm/1 for an event with no recurrences, but occurs in future" do
    event_without_recurrences = Fixtures.one_event(:future_no_recurrences)

    actual_next_alarms = ICal.Alarm.next_alarms(event_without_recurrences)
    expected_next_alarms = Fixtures.alarm(:trigger_start)

    assert [{%DateTime{}, ^expected_next_alarms}] = actual_next_alarms
  end

  test "next_alarm/1 for an event with no recurrences, but trigger for alarm is `:end`, and end is in future" do
    event_without_recurrences = Fixtures.one_event(:future_no_recurrences_trigger_end)

    actual_next_alarms = ICal.Alarm.next_alarms(event_without_recurrences)
    expected_next_alarms = Fixtures.alarm(:trigger_end)

    assert [{%DateTime{}, ^expected_next_alarms}] = actual_next_alarms
  end
end
