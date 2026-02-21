defmodule ICalTest do
  use ExUnit.Case
  use ICal.Test.Helper

  alias ICal.Test.Fixtures

  @vendor "ICal Test"

  test "ICal.to_ics/1 of empty calendar" do
    ics = %ICal{} |> ICal.to_ics() |> to_string()

    assert ics == """
           BEGIN:VCALENDAR
           CALSCALE:GREGORIAN
           VERSION:2.0
           PRODID:#{Helper.product_id()}
           END:VCALENDAR
           """
  end

  test "ICal.to_ics/1 of empty calendar with nil values" do
    ics =
      %ICal{scale: nil, version: nil, product_id: nil} |> ICal.to_ics() |> to_string()

    assert ics == """
           BEGIN:VCALENDAR
           VERSION:2.0
           PRODID:#{Helper.product_id()}
           END:VCALENDAR
           """
  end

  test "ICal.to_ics/1 of empty calendar with custom vendor" do
    ics = %ICal{} |> ICal.set_vendor(@vendor) |> ICal.to_ics() |> to_string()

    assert ics == """
           BEGIN:VCALENDAR
           CALSCALE:GREGORIAN
           VERSION:2.0
           PRODID:#{Helper.product_id(@vendor)}
           END:VCALENDAR
           """
  end

  test "ICal.to_ics/1 of empty calendar with method" do
    ics = %ICal{method: "REQUEST"} |> ICal.to_ics() |> to_string()

    assert ics == """
           BEGIN:VCALENDAR
           CALSCALE:GREGORIAN
           VERSION:2.0
           PRODID:#{Helper.product_id()}
           METHOD:REQUEST
           END:VCALENDAR
           """
  end

  test "ICal metadata is correctly parsed" do
    calendar = Helper.test_data("empty_calendar") |> ICal.from_ics()
    assert Fixtures.calendar(:empty) == calendar

    assert calendar.scale == "GREGORIAN"
    assert calendar.version == "2.0"
    assert calendar.product_id == "-//Elixir ICal//EN"
    assert calendar.method == "REQUEST"
    assert calendar.default_timezone == "Etc/UTC"
    assert calendar.custom_properties == %{}
  end

  test "ICal metadata with custom headers is correctly parsed" do
    calendar = Helper.test_data("custom_calendar_entries") |> ICal.from_ics()
    assert Fixtures.calendar(:custom_properties) == calendar
  end

  test "ICal metadata with custom headers is correctly serialized" do
    calendar = Helper.test_data("custom_calendar_entries") |> ICal.from_ics()
    assert Fixtures.calendar(:custom_properties) == calendar
  end

  test "ICal with custom tz alter dates" do
    dtstamp = Timex.to_datetime({{2015, 12, 24}, {8, 0, 00}})

    %ICal{events: [%ICal.Event{dtstamp: parsed_date}]} =
      Helper.test_data("custom_calendar_tz") |> ICal.from_ics()

    assert dtstamp != parsed_date
    assert parsed_date.time_zone == "Europe/Zurich"
  end

  test "ICal.to_ics/1 of a calendar with an event, as in README" do
    expected = """
    BEGIN:VCALENDAR
    CALSCALE:GREGORIAN
    VERSION:2.0
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
    END:VCALENDAR
    """

    events = [
      %ICal.Event{
        summary: "Film with Amy and Adam",
        dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 00}}),
        dtstamp: Timex.to_datetime({{2015, 12, 23}, {19, 00, 00}}),
        dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
        description: "Let's go see Star Wars."
      },
      %ICal.Event{
        summary: "Morning meeting",
        dtstart: Timex.to_datetime({{2015, 12, 24}, {19, 00, 00}}),
        dtstamp: Timex.to_datetime({{2015, 12, 24}, {15, 00, 00}}),
        dtend: Timex.to_datetime({{2015, 12, 24}, {22, 30, 00}}),
        description: "A big long meeting with lots of details."
      }
    ]

    %ICal{events: events}
    |> ICal.to_ics()
    |> assert_fully_contains(expected)
  end

  test "Icalender.to_ics/1 with location and sanitization" do
    expected = """
    BEGIN:VCALENDAR
    CALSCALE:GREGORIAN
    VERSION:2.0
    BEGIN:VEVENT
    DESCRIPTION:Let's go see Star Wars\\, and have fun.
    DTEND:20151224T084500Z
    DTSTAMP:20151224T080000Z
    DTSTART:20151224T083000Z
    LOCATION:123 Fun Street\\, Toronto ON\\, Canada
    SUMMARY:Film with Amy and Adam
    END:VEVENT
    END:VCALENDAR
    """

    events = [
      %ICal.Event{
        summary: "Film with Amy and Adam",
        dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 00}}),
        dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 00}}),
        dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
        description: "Let's go see Star Wars, and have fun.",
        location: "123 Fun Street, Toronto ON, Canada"
      }
    ]

    %ICal{events: events}
    |> ICal.to_ics()
    |> assert_fully_contains(expected)
  end

  test "Icalender.to_ics/1 with url" do
    expected = """
    BEGIN:VCALENDAR
    CALSCALE:GREGORIAN
    VERSION:2.0
    BEGIN:VEVENT
    DESCRIPTION:Let's go see Star Wars\\, and have fun.
    DTEND:20151224T084500Z
    DTSTAMP:20151224T080000Z
    DTSTART:20151224T083000Z
    LOCATION:123 Fun Street\\, Toronto ON\\, Canada
    SUMMARY:Film with Amy and Adam
    URL:http://example.com/tr3GE5
    END:VEVENT
    END:VCALENDAR
    """

    events = [
      %ICal.Event{
        summary: "Film with Amy and Adam",
        dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 00}}),
        dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 00}}),
        dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
        description: "Let's go see Star Wars, and have fun.",
        location: "123 Fun Street, Toronto ON, Canada",
        url: "http://example.com/tr3GE5"
      }
    ]

    %ICal{events: events}
    |> ICal.to_ics()
    |> assert_fully_contains(expected)
  end

  test "ICalender.to_ics/1 with exdates" do
    events = [
      %ICal.Event{
        exdates: [
          Timex.Timezone.convert(~U[2020-09-16 18:30:00Z], "America/Toronto"),
          Timex.Timezone.convert(~U[2020-09-17 18:30:00Z], "America/Toronto")
        ]
      }
    ]

    ics =
      %ICal{events: events}
      |> ICal.to_ics()
      |> to_string()

    assert ics =~ "EXDATE;TZID=America/Toronto:20200916T143000"
    assert ics =~ "EXDATE;TZID=America/Toronto:20200917T143000"
  end

  test "ICalender.to_ics/1 with duration" do
    events = [
      %ICal.Event{
        duration: %ICal.Duration{
          days: 15,
          positive: true,
          time: {5, 0, 20},
          weeks: 0
        }
      }
    ]

    ics =
      %ICal{events: events}
      |> ICal.to_ics()
      |> to_string()

    assert ics =~ "DURATION:P15DT5H20S"
  end

  test "ICalender.to_ics/1 with RECURRENCE-ID in UTC" do
    events = [
      %ICal.Event{
        recurrence_id: ~U[2020-09-17 14:30:00Z],
        summary: "Modified instance"
      }
    ]

    ics =
      %ICal{events: events}
      |> ICal.to_ics()
      |> to_string()

    assert ics =~ "RECURRENCE-ID:20200917T143000Z"
  end

  test "ICalender.to_ics/1 with RECURRENCE-ID with timezone" do
    recurrence_id = Timex.Timezone.convert(~U[2020-09-17 18:30:00Z], "America/Toronto")

    events = [
      %ICal.Event{
        recurrence_id: recurrence_id,
        summary: "Modified instance"
      }
    ]

    ics =
      %ICal{events: events}
      |> ICal.to_ics()
      |> to_string()

    assert ics =~ "RECURRENCE-ID;TZID=America/Toronto:20200917T143000"
  end

  test "ICalender.to_ics/1 -> ICal.from_ics/1 and back again" do
    events = [
      %ICal.Event{
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
      %ICal{events: events}
      |> ICal.to_ics()
      |> to_string()
      |> ICal.from_ics()

    assert events |> List.first() == new_event
  end

  test "ICalender.to_ics/1 -> ICal.from_ics/1 and back again, with newlines" do
    events = [
      %ICal.Event{
        summary: "Film with Amy and Adam",
        dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 00}}),
        dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 00}}),
        dtstamp: Timex.to_datetime({{2017, 12, 24}, {8, 00, 00}}),
        description: "First line\nThis is a new line\n\nDouble newline",
        location: "123 Fun Street, Toronto ON, Canada",
        url: "http://www.example.com"
      }
    ]

    %ICal{events: [new_event]} =
      %ICal{events: events}
      |> ICal.to_ics()
      |> to_string()
      |> ICal.from_ics()

    assert events |> List.first() == new_event
  end

  test "ICalender.to_ics/1 supports bare components and lists of components" do
    assert %ICal{events: [%ICal.Event{}]}
           |> ICal.to_ics()
           |> to_string()
           |> String.count("BEGIN:VEVENT") == 1

    assert %ICal{events: [%ICal.Event{}]}
           |> ICal.to_ics()
           |> to_string()
           |> String.count("BEGIN:VCALENDAR") == 1

    assert %ICal.Event{}
           |> ICal.to_ics()
           |> to_string()
           |> String.count("BEGIN:VEVENT") == 1

    assert %ICal.Event{}
           |> ICal.to_ics()
           |> to_string()
           |> String.count("BEGIN:VCALENDAR") == 0

    assert %ICal.Todo{}
           |> ICal.to_ics()
           |> to_string()
           |> String.count("BEGIN:VTODO") == 1

    assert %ICal.Todo{}
           |> ICal.to_ics()
           |> to_string()
           |> String.count("BEGIN:VCALENDAR") == 0

    assert [%ICal.Event{}, %ICal.Event{}]
           |> ICal.to_ics()
           |> to_string()
           |> String.count("BEGIN:VEVENT") == 2

    assert [%ICal.Event{}, %ICal.Todo{}]
           |> ICal.to_ics()
           |> Enum.count() == 2

    assert [%ICal.Event{}, %ICal.Todo{}]
           |> ICal.to_ics()
           |> to_string()
           |> String.count("BEGIN:VEVENT") == 1

    assert [%ICal.Event{}, %ICal.Todo{}]
           |> ICal.to_ics()
           |> to_string()
           |> String.count("BEGIN:VTODO") == 1
  end

  test "encode_to_iodata/2" do
    expected = Helper.test_data("iodata_calendar")
    assert {:ok, ical} = ICal.encode_to_iodata(Fixtures.iodata_calendar(), [])
    assert_fully_contains(ical, expected)
  end

  test "encode_to_iodata/1" do
    expected = Helper.test_data("iodata_calendar")
    assert {:ok, ical} = ICal.encode_to_iodata(Fixtures.iodata_calendar())
    assert_fully_contains(ical, expected)
  end

  test "Unrecognized properties are kept" do
    ics = Helper.test_data("unrecognized_component")
    calendar = ICal.from_ics(ics)

    expected = [
      "BEGIN:CUSTOM\n",
      {"KEY", %{"PARAM" => "param_value"}, "Value for KEY"},
      {"KEY2", %{"PARAM" => "param_value"}, "Value for KEY2"},
      "END:CUSTOM\n"
    ]

    assert calendar.__other_components == [expected]

    serialized = ICal.to_ics(calendar) |> to_string()
    assert serialized == ics
  end

  test "Names are supported" do
    calendar = "calendar_name" |> Helper.test_data() |> ICal.from_ics()
    assert calendar.name == "This is my name"

    calendar = "calendar_x_name" |> Helper.test_data() |> ICal.from_ics()
    assert calendar.name == "This is my name"
  end
end
