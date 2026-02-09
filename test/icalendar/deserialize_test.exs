defmodule ICalendar.DeserializeTest do
  use ExUnit.Case

  alias ICalendar.Event
  alias ICalendar.Test.Helper

  describe "ICalendar.from_ics/1" do
    test "Single Event" do
      ics = Helper.test_data("one_event")
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
      ics = Helper.test_data("one_event_desc_summary")

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
      ics = Helper.test_data("timezone_event")
      %ICalendar{events: [event]} = ICalendar.from_ics(ics)
      assert event.dtstart.time_zone == "America/Chicago"
      assert event.dtend.time_zone == "America/Chicago"
    end

    test "with CR+LF line endings" do
      ics = Helper.test_data("cr_lf")

      %ICalendar{events: [event]} = ICalendar.from_ics(ics)
      assert event.description == "CR+LF line endings"
    end

    test "with URL" do
      ics = Helper.test_data("event_with_url")
      %ICalendar{events: [event]} = ICalendar.from_ics(ics)
      assert event.url == "http://google.com"
    end

    test "Event with RECURRENCE-ID in UTC" do
      ics = Helper.test_data("event_with_recurrence_id")
      %ICalendar{events: [event]} = ICalendar.from_ics(ics)
      assert event.recurrence_id == ~U[2020-09-17 14:30:00Z]
    end

    test "Event with RECURRENCE-ID with TZID" do
      ics = Helper.test_data("event_with_recurrence_id_tz")
      %ICalendar{events: [event]} = ICalendar.from_ics(ics)
      expected = Timex.Timezone.convert(~U[2020-09-17 18:30:00Z], "America/Toronto")
      assert event.recurrence_id == expected
    end

    test "Event with RECURRENCE-ID as DATE" do
      ics = Helper.test_data("event_with_recurrence_id_date")
      %ICalendar{events: [event]} = ICalendar.from_ics(ics)
      assert event.recurrence_id == ~U[2020-09-17 00:00:00Z]
    end
  end
end
