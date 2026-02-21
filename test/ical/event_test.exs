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

    %Event{dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}})}
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
      dtstart: Timex.to_date({2015, 12, 24}),
      dtend: Timex.to_date({2015, 12, 24}),
      dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}})
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
      dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 00}}),
      dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
      dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}})
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
      dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 00}}),
      dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
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

    dtstart =
      {{2015, 12, 24}, {8, 30, 00}}
      |> Timex.to_datetime("America/Chicago")

    dtend =
      {{2015, 12, 24}, {8, 45, 00}}
      |> Timex.to_datetime("America/Chicago")

    %Event{
      dtstart: dtstart,
      dtend: dtend,
      dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}})
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
      dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}})
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
      dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}})
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
      dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}})
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
      dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}})
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
      dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}})
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
      dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}})
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
      dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}})
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
      dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}})
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
end
