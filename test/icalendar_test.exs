defmodule ICalendarTest do
  use ExUnit.Case
  alias ICalendar.Test.Helper
  alias ICalendar.Test.Fixtures

  @vendor "ICalendar Test"

  test "ICalendar.to_ics/1 of empty calendar" do
    ics = %ICalendar{} |> ICalendar.to_ics() |> to_string()

    assert ics == """
           BEGIN:VCALENDAR
           CALSCALE:GREGORIAN
           VERSION:2.0
           PRODID:-//Elixir ICalendar//EN
           END:VCALENDAR
           """
  end

  test "ICalendar.to_ics/1 of empty calendar with nil values" do
    ics =
      %ICalendar{scale: nil, version: nil, product_id: nil} |> ICalendar.to_ics() |> to_string()

    assert ics == """
           BEGIN:VCALENDAR
           VERSION:2.0
           END:VCALENDAR
           """
  end

  test "ICalendar.to_ics/1 of empty calendar with custom vendor" do
    ics = %ICalendar{} |> ICalendar.set_vendor(@vendor) |> ICalendar.to_ics() |> to_string()

    assert ics == """
           BEGIN:VCALENDAR
           CALSCALE:GREGORIAN
           VERSION:2.0
           PRODID:-//Elixir ICalendar//#{@vendor}//EN
           END:VCALENDAR
           """
  end

  test "ICalendar.to_ics/1 of empty calendar with method" do
    ics = %ICalendar{method: "REQUEST"} |> ICalendar.to_ics() |> to_string()

    assert ics == """
           BEGIN:VCALENDAR
           CALSCALE:GREGORIAN
           VERSION:2.0
           PRODID:-//Elixir ICalendar//EN
           METHOD:REQUEST
           END:VCALENDAR
           """
  end

  test "ICalendar metadata is correctly parsed" do
    calendar = Helper.test_data("empty_calendar") |> ICalendar.from_ics()

    assert calendar.scale == "GREGORIAN"
    assert calendar.version == "2.0"
    assert calendar.product_id == "-//Elixir ICalendar//EN"
    assert calendar.method == "REQUEST"
  end

  test "ICalendar.to_ics/1 of a calendar with an event, as in README" do
    events = [
      %ICalendar.Event{
        summary: "Film with Amy and Adam",
        dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 00}}),
        dtstamp: Timex.to_datetime({{2015, 12, 23}, {19, 00, 00}}),
        dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
        description: "Let's go see Star Wars."
      },
      %ICalendar.Event{
        summary: "Morning meeting",
        dtstart: Timex.to_datetime({{2015, 12, 24}, {19, 00, 00}}),
        dtstamp: Timex.to_datetime({{2015, 12, 24}, {15, 00, 00}}),
        dtend: Timex.to_datetime({{2015, 12, 24}, {22, 30, 00}}),
        description: "A big long meeting with lots of details."
      }
    ]

    ics = %ICalendar{events: events} |> ICalendar.to_ics() |> Helper.extract_event_props()

    assert ics == """
           BEGIN:VEVENT
           DESCRIPTION:Let's go see Star Wars.
           DTEND:20151224T084500Z
           DTSTAMP:20151223T190000Z
           DTSTART:20151224T083000Z
           SUMMARY:Film with Amy and Adam
           END:VEVENT
           BEGIN:VEVENT
           DESCRIPTION:A big long meeting with lots of details.
           DTEND:20151224T223000Z
           DTSTAMP:20151224T150000Z
           DTSTART:20151224T190000Z
           SUMMARY:Morning meeting
           END:VEVENT
           """
  end

  test "Icalender.to_ics/1 with location and sanitization" do
    events = [
      %ICalendar.Event{
        summary: "Film with Amy and Adam",
        dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 00}}),
        dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 00}}),
        dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
        description: "Let's go see Star Wars, and have fun.",
        location: "123 Fun Street, Toronto ON, Canada"
      }
    ]

    ics =
      %ICalendar{events: events}
      |> ICalendar.to_ics()
      |> Helper.extract_event_props()

    assert ics == """
           BEGIN:VEVENT
           DESCRIPTION:Let's go see Star Wars\\, and have fun.
           DTEND:20151224T084500Z
           DTSTAMP:20151224T080000Z
           DTSTART:20151224T083000Z
           LOCATION:123 Fun Street\\, Toronto ON\\, Canada
           SUMMARY:Film with Amy and Adam
           END:VEVENT
           """
  end

  test "Icalender.to_ics/1 with url" do
    events = [
      %ICalendar.Event{
        summary: "Film with Amy and Adam",
        dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 00}}),
        dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 00}}),
        dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
        description: "Let's go see Star Wars, and have fun.",
        location: "123 Fun Street, Toronto ON, Canada",
        url: "http://example.com/tr3GE5"
      }
    ]

    ics = %ICalendar{events: events} |> ICalendar.to_ics() |> Helper.extract_event_props()

    assert ics == """
           BEGIN:VEVENT
           DESCRIPTION:Let's go see Star Wars\\, and have fun.
           DTEND:20151224T084500Z
           DTSTAMP:20151224T080000Z
           DTSTART:20151224T083000Z
           LOCATION:123 Fun Street\\, Toronto ON\\, Canada
           SUMMARY:Film with Amy and Adam
           URL:http://example.com/tr3GE5
           END:VEVENT
           """
  end

  test "ICalender.to_ics/1 with rrule" do
    events = [
      %ICalendar.Event{
        dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 00}}),
        rrule: %{
          byday: ["TH", "WE"],
          freq: "WEEKLY",
          bysetpos: [-1],
          interval: -2,
          until: ~U[2020-12-04 04:59:59Z]
        }
      }
    ]

    ics =
      %ICalendar{events: events}
      |> ICalendar.to_ics()
      |> to_string()

    # Extract RRULE line for comparison (parameter order doesn't matter per RFC 5545)
    [rrule_line] = Regex.run(~r/RRULE:(.+)/, ics, capture: :all_but_first)

    rrule_params =
      rrule_line
      |> String.split(";")
      |> MapSet.new()

    expected_params =
      MapSet.new([
        "FREQ=WEEKLY",
        "BYDAY=TH,WE",
        "BYSETPOS=-1",
        "INTERVAL=-2",
        "UNTIL=20201204T045959"
      ])

    assert rrule_params == expected_params
  end

  test "ICalender.to_ics/1 with exdates" do
    events = [
      %ICalendar.Event{
        exdates: [
          Timex.Timezone.convert(~U[2020-09-16 18:30:00Z], "America/Toronto"),
          Timex.Timezone.convert(~U[2020-09-17 18:30:00Z], "America/Toronto")
        ]
      }
    ]

    ics =
      %ICalendar{events: events}
      |> ICalendar.to_ics()
      |> to_string()

    assert ics =~ "EXDATE;TZID=America/Toronto:20200916T143000"
    assert ics =~ "EXDATE;TZID=America/Toronto:20200917T143000"
  end

  test "ICalender.to_ics/1 with RECURRENCE-ID in UTC" do
    events = [
      %ICalendar.Event{
        recurrence_id: ~U[2020-09-17 14:30:00Z],
        summary: "Modified instance"
      }
    ]

    ics =
      %ICalendar{events: events}
      |> ICalendar.to_ics()
      |> to_string()

    assert ics =~ "RECURRENCE-ID:20200917T143000Z"
  end

  test "ICalender.to_ics/1 with RECURRENCE-ID with timezone" do
    recurrence_id = Timex.Timezone.convert(~U[2020-09-17 18:30:00Z], "America/Toronto")

    events = [
      %ICalendar.Event{
        recurrence_id: recurrence_id,
        summary: "Modified instance"
      }
    ]

    ics =
      %ICalendar{events: events}
      |> ICalendar.to_ics()
      |> to_string()

    assert ics =~ "RECURRENCE-ID;TZID=America/Toronto:20200917T143000"
  end

  test "Icalender.to_ics/1 with default value for DTSTAMP" do
    events = [
      %ICalendar.Event{
        summary: "Film with Amy and Adam",
        dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 00}}),
        dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
        description: "Let's go see Star Wars, and have fun."
      }
    ]

    props =
      %ICalendar{events: events}
      |> ICalendar.to_ics()
      |> Helper.extract_event_props()

    assert props == """
           BEGIN:VEVENT
           DESCRIPTION:Let's go see Star Wars\\, and have fun.
           DTEND:20151224T084500Z
           DTSTAMP:#{ICalendar.Serialize.to_ics(DateTime.utc_now())}Z
           DTSTART:20151224T083000Z
           SUMMARY:Film with Amy and Adam
           END:VEVENT
           """
  end

  test "ICalender.to_ics/1 -> ICalendar.from_ics/1 and back again" do
    events = [
      %ICalendar.Event{
        summary: "Film with Amy and Adam",
        dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 00}}),
        dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 00}}),
        dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
        description: "Let's go see Star Wars, and have fun.",
        location: "123 Fun Street, Toronto ON, Canada",
        url: "http://www.example.com"
      }
    ]

    %{events: [new_event]} =
      %ICalendar{events: events}
      |> ICalendar.to_ics()
      |> to_string()
      |> ICalendar.from_ics()

    assert events |> List.first() == new_event
  end

  test "ICalender.to_ics/1 -> ICalendar.from_ics/1 and back again, with newlines" do
    events = [
      %ICalendar.Event{
        summary: "Film with Amy and Adam",
        dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 00}}),
        dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
        dtstamp: Timex.to_datetime({{2017, 12, 24}, {8, 00, 00}}),
        description: "First line\nThis is a new line\n\nDouble newline",
        location: "123 Fun Street, Toronto ON, Canada",
        url: "http://www.example.com"
      }
    ]

    %ICalendar{events: [new_event]} =
      %ICalendar{events: events}
      |> ICalendar.to_ics()
      |> to_string()
      |> ICalendar.from_ics()

    assert events |> List.first() == new_event
  end

  test "encode_to_iodata/2" do
    events = [
      %ICalendar.Event{
        summary: "Film with Amy and Adam",
        dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 00}}),
        dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 00}}),
        dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
        description: "Let's go see Star Wars."
      },
      %ICalendar.Event{
        summary: "Morning meeting",
        dtstart: Timex.to_datetime({{2015, 12, 24}, {19, 00, 00}}),
        dtstamp: Timex.to_datetime({{2015, 12, 24}, {18, 00, 00}}),
        dtend: Timex.to_datetime({{2015, 12, 24}, {22, 30, 00}}),
        description: "A big long meeting with lots of details."
      }
    ]

    cal = %ICalendar{events: events}

    assert {:ok, ical} = ICalendar.encode_to_iodata(cal, [])

    assert Helper.extract_event_props(ical) == """
           BEGIN:VEVENT
           DESCRIPTION:Let's go see Star Wars.
           DTEND:20151224T084500Z
           DTSTAMP:20151224T080000Z
           DTSTART:20151224T083000Z
           SUMMARY:Film with Amy and Adam
           END:VEVENT
           BEGIN:VEVENT
           DESCRIPTION:A big long meeting with lots of details.
           DTEND:20151224T223000Z
           DTSTAMP:20151224T180000Z
           DTSTART:20151224T190000Z
           SUMMARY:Morning meeting
           END:VEVENT
           """
  end

  test "encode_to_iodata/1" do
    events = [
      %ICalendar.Event{
        summary: "Film with Amy and Adam",
        dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 00}}),
        dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 00}}),
        dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
        description: "Let's go see Star Wars."
      },
      %ICalendar.Event{
        summary: "Morning meeting",
        dtstart: Timex.to_datetime({{2015, 12, 24}, {19, 00, 00}}),
        dtstamp: Timex.to_datetime({{2015, 12, 24}, {18, 00, 00}}),
        dtend: Timex.to_datetime({{2015, 12, 24}, {22, 30, 00}}),
        description: "A big long meeting with lots of details."
      }
    ]

    cal = %ICalendar{events: events}

    assert {:ok, ical} = ICalendar.encode_to_iodata(cal)

    assert Helper.extract_event_props(ical) == """
           BEGIN:VEVENT
           DESCRIPTION:Let's go see Star Wars.
           DTEND:20151224T084500Z
           DTSTAMP:20151224T080000Z
           DTSTART:20151224T083000Z
           SUMMARY:Film with Amy and Adam
           END:VEVENT
           BEGIN:VEVENT
           DESCRIPTION:A big long meeting with lots of details.
           DTEND:20151224T223000Z
           DTSTAMP:20151224T180000Z
           DTSTART:20151224T190000Z
           SUMMARY:Morning meeting
           END:VEVENT
           """
  end

  test "encode attendees" do
    calendar = Fixtures.attendees()

    ics =
      calendar
      |> ICalendar.to_ics()
      |> Helper.extract_event_props()

    expected = """
    BEGIN:VEVENT
    ATTENDEE;MEMBER="mailto:projectA@example.com","mailto:projectB@example.com";ROLE=CHAIR;DELEGATED-TO="mailto:jdoe@example.com","mailto:jqpublic@example.com":mailto:janedoe@example.com
    ATTENDEE;RSVP=TRUE;DELEGATED-FROM="mailto:jsmith@example.com":mailto:jdoe@example.com
    ATTENDEE;LANGUAGE=de-ch;CUTYPE=GROUP;PARTSTAT=ACCEPTED;SENT-BY="mailto:sray@example.com";CN="John Smith";DIR="ldap://example.com:6666/o=ABC%20Industries,c=US???(cn=Jim%20Dolittle)":mailto:ietf-calsch@example.org
    DESCRIPTION:An event with attendees
    DTSTAMP:20151224T080000Z
    UID:01
    END:VEVENT
    """

    assert ics == expected
  end
end
