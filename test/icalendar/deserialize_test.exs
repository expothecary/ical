defmodule ICalendar.DeserializeTest do
  use ExUnit.Case

  alias ICalendar.Event

  describe "ICalendar.from_ics/1" do
    test "Single Event" do
      ics = """
      BEGIN:VEVENT
      DESCRIPTION:Escape from the world. Stare at some water.
      COMMENT:Don't forget to take something to eat !
      SUMMARY:Going fishing
      DTEND:20151224T084500Z
      DTSTAMP:20151224T080000Z
      DTSTART:20151224T083000Z
      LOCATION:123 Fun Street\\, Toronto ON\\, Canada
      STATUS:TENTATIVE
      CATEGORIES:Fishing,Nature
      CLASS:PRIVATE
      GEO:43.6978819;-79.3810277
      END:VEVENT
      """

      %ICalendar{events: [event]} = ICalendar.from_ics(ics)

      assert event == %Event{
               dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 0}}),
               dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 0}}),
               dtstamp: Timex.to_datetime({{2015, 12, 24}, {8, 00, 0}}),
               summary: "Going fishing",
               description: "Escape from the world. Stare at some water.",
               location: "123 Fun Street, Toronto ON, Canada",
               status: :tentative,
               categories: ["Fishing", "Nature"],
               comments: ["Don't forget to take something to eat !"],
               class: "PRIVATE",
               geo: {43.6978819, -79.3810277}
             }
    end

    test "Single event with wrapped description and summary" do
      ics = """
      BEGIN:VEVENT
      DESCRIPTION:Escape from the world. Stare at some water. Maybe you'll even
        catch some fish!
      COMMENT:Don't forget to take something to eat !
      SUMMARY:Going fishing at the lake that happens to be in the middle of fun
        street.
      DTEND:20151224T084500Z
      DTSTART:20151224T083000Z
      LOCATION:123 Fun Street\\, Toronto ON\\, Canada
      STATUS:TENTATIVE
      CATEGORIES:Fishing,Nature
      CLASS:PRIVATE
      GEO:43.6978819;-79.3810277
      END:VEVENT
      """

      %ICalendar{events: [event]} = ICalendar.from_ics(ics)

      assert event == %Event{
               dtstart: Timex.to_datetime({{2015, 12, 24}, {8, 30, 0}}),
               dtend: Timex.to_datetime({{2015, 12, 24}, {8, 45, 0}}),
               summary:
                 "Going fishing at the lake that happens to be in the middle of fun street.",
               description:
                 "Escape from the world. Stare at some water. Maybe you'll even catch some fish!",
               location: "123 Fun Street, Toronto ON, Canada",
               status: :tentative,
               categories: ["Fishing", "Nature"],
               comments: ["Don't forget to take something to eat !"],
               class: "PRIVATE",
               geo: {43.6978819, -79.3810277}
             }
    end

    test "with Timezone" do
      ics = """
      BEGIN:VEVENT
      DTEND;TZID=America/Chicago:22221224T084500
      DTSTART;TZID=America/Chicago:22221224T083000
      END:VEVENT
      """

      %ICalendar{events: [event]} = ICalendar.from_ics(ics)
      assert event.dtstart.time_zone == "America/Chicago"
      assert event.dtend.time_zone == "America/Chicago"
    end

    test "with CR+LF line endings" do
      ics = """
      BEGIN:VEVENT
      DESCRIPTION:CR+LF line endings\r\nSUMMARY:Going fishing\r
      DTEND:20151224T084500Z\r\nDTSTART:20151224T083000Z\r
      END:VEVENT
      """

      %ICalendar{events: [event]} = ICalendar.from_ics(ics)
      assert event.description == "CR+LF line endings"
    end

    test "with URL" do
      ics = """
      BEGIN:VEVENT
      DESCRIPTION:Escape from the world. Stare at some water.
      COMMENT:Don't forget to take something to eat !
      URL:http://google.com
      SUMMARY:Going fishing
      DTEND:20151224T084500Z
      DTSTART:20151224T083000Z
      LOCATION:123 Fun Street\\, Toronto ON\\, Canada
      STATUS:TENTATIVE
      CATEGORIES:Fishing,Nature
      CLASS:PRIVATE
      GEO:43.6978819;-79.3810277
      END:VEVENT
      """

      %ICalendar{events: [event]} = ICalendar.from_ics(ics)
      assert event.url == "http://google.com"
    end

    test "Event with RECURRENCE-ID in UTC" do
      ics = """
      BEGIN:VEVENT
      UID:event-123
      DTSTART:20200917T143000Z
      RECURRENCE-ID:20200917T143000Z
      SUMMARY:Modified instance
      END:VEVENT
      """

      %ICalendar{events: [event]} = ICalendar.from_ics(ics)
      assert event.recurrence_id == ~U[2020-09-17 14:30:00Z]
    end

    test "Event with RECURRENCE-ID with TZID" do
      ics = """
      BEGIN:VEVENT
      UID:event-123
      DTSTART;TZID=America/Toronto:20200917T143000
      RECURRENCE-ID;TZID=America/Toronto:20200917T143000
      SUMMARY:Modified instance
      END:VEVENT
      """

      %ICalendar{events: [event]} = ICalendar.from_ics(ics)
      expected = Timex.Timezone.convert(~U[2020-09-17 18:30:00Z], "America/Toronto")
      assert event.recurrence_id == expected
    end

    test "Event with RECURRENCE-ID as DATE" do
      ics = """
      BEGIN:VEVENT
      UID:event-123
      DTSTART;VALUE=DATE:20200917
      RECURRENCE-ID;VALUE=DATE:20200917
      SUMMARY:Modified instance
      END:VEVENT
      """

      %ICalendar{events: [event]} = ICalendar.from_ics(ics)
      assert event.recurrence_id == ~U[2020-09-17 00:00:00Z]
    end
  end
end
