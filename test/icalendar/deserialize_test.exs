defmodule ICalendar.DeserializeTest do
  use ExUnit.Case

  alias ICalendar.Event
  alias ICalendar.Test.Helper
  alias ICalendar.Test.Fixtures

  describe "ICalendar.from_ics/1" do
    test "Single Event" do
      ics = Helper.test_data("one_event")
      %ICalendar{events: [event]} = ICalendar.from_ics(ics)

      assert event == Fixtures.one_event()
    end

    test "Single Event from a file" do
      ics = Helper.test_data_path("one_event")
      %ICalendar{events: [event]} = ICalendar.from_file(ics)

      assert event == Fixtures.one_event()
    end

    test "Single Event via Event.from_ics" do
      ics = Helper.test_data("one_event")
      assert ICalendar.Event.from_ics(ics) == Fixtures.one_event()
    end

    test "Truncated data is handled gracefully" do
      ics = Helper.test_data("truncated_event")
      assert ICalendar.Event.from_ics(ics) == Fixtures.one_event()
    end

    test "Deserializing a non-extant file returns an :error tuple" do
      assert ICalendar.from_file("/does/not/exist.ics") == {:error, :enoent}
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

    test "Event with attachments" do
      ics = Helper.test_data("attachments")
      %ICalendar{events: [event]} = ICalendar.from_ics(ics)
      assert Enum.count(event.attachments) == 5

      [a1, a2, a3, a4, a5] = event.attachments

      # a CID attachment
      assert a1.data_type == :cid
      assert a1.data == "jsmith.part3.960817T083000.xyzMail@example.com"

      # a URL with a mimetype
      assert a2.data_type == :uri
      assert a2.data == "ftp://example.com/pub/reports/r-960812.ps"
      assert a2.mimetype == "application/postscript"
      assert ICalendar.Attachment.decoded_data(a2) == {:ok, a2.data}

      # an inline 8bit attachment, no mimetype
      assert a3.data_type == :base8
      assert a3.mimetype == nil
      assert a3.data == "Some plain text"

      # an inline base64-encoded attachment with no padding
      assert a4.data_type == :base64
      assert a4.mimetype == "text/plain"

      assert ICalendar.Attachment.decoded_data(a4) ==
               {:ok, "The quick brown fox jumps over the lazy dog."}

      # an inline base64-encoded attachment with padding
      assert a5.data_type == :base64
      assert {:ok, long_text} = ICalendar.Attachment.decoded_data(a5)
      assert String.starts_with?(long_text, "Lorem ipsum dolor sit amet,")
      assert String.length(long_text) == 446
      assert a5.mimetype == "text/plain"
    end

    test "Event with attendees" do
      ics = Helper.test_data("attendees")
      %ICalendar{events: [event]} = ICalendar.from_ics(ics)
      assert Enum.count(event.attendees) == 3

      [a1, a2, a3] = event.attendees

      assert a1.name == "mailto:janedoe@example.com"
      assert a1.membership == ["mailto:projectA@example.com", "mailto:projectB@example.com"]
      assert a1.delegated_to == ["mailto:jdoe@example.com", "mailto:jqpublic@example.com"]
      assert a1.rsvp == false
      assert a1.role == "CHAIR"

      assert a2.delegated_from == ["mailto:jsmith@example.com"]
      assert a2.rsvp == true
      assert is_nil(a2.role)

      assert a3.type == "GROUP"
      assert a3.status == "ACCEPTED"
      assert a3.sent_by == "mailto:sray@example.com"
      assert a3.cname == "John Smith"
      assert a3.dir == "ldap://example.com:6666/o=ABC%20Industries,c=US???(cn=Jim%20Dolittle)"
      assert a3.language == "de-ch"
    end
  end
end
