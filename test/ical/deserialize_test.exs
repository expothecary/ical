defmodule ICal.DeserializeTest do
  use ExUnit.Case

  alias ICal.Event
  alias ICal.Test.Fixtures
  alias ICal.Test.Helper

  describe "ICal.Deserialize" do
    test "Comma separated list parsing" do
      assert {"", []} == ICal.Deserialize.comma_separated_list("")
      assert {"", []} == ICal.Deserialize.comma_separated_list("\n")
      assert {"", []} == ICal.Deserialize.comma_separated_list("\r\n")

      assert {"", ["a", "b"]} == ICal.Deserialize.comma_separated_list(~S"a,b")
      assert {"", ["a", "b"]} == ICal.Deserialize.comma_separated_list(~S"a,,b")
      assert {"", ["a\n", "b"]} == ICal.Deserialize.comma_separated_list(~S"\a\n,b")
    end

    test "Multi-line parsing" do
      assert {"", nil} == ICal.Deserialize.multi_line("")
      assert {"", nil} == ICal.Deserialize.multi_line("\n")
      assert {"", nil} == ICal.Deserialize.multi_line("\r\n")
      assert {"", "ab"} == ICal.Deserialize.multi_line("a\n b")
      assert {"", "a  b"} == ICal.Deserialize.multi_line("a\r\n   b")
      assert {"", "ab c"} == ICal.Deserialize.multi_line("a\r\n\tb\n\t c")
      assert {"MORE", "a b c"} == ICal.Deserialize.multi_line("a\r\n\t b\n\t c\nMORE")
    end

    test "Skipping params" do
      assert "" == ICal.Deserialize.skip_params("")
      assert "\n" == ICal.Deserialize.skip_params("\n")
      assert "\r\n" == ICal.Deserialize.skip_params("\r\n")
      assert "VALUE" == ICal.Deserialize.skip_params(":VALUE")
      assert "VALUE" == ICal.Deserialize.skip_params(~S|;PARAM=VAR:VALUE|)
      assert "VALUE" == ICal.Deserialize.skip_params(~S|;PARAM=VAR\::VALUE|)
      assert "VALUE" == ICal.Deserialize.skip_params(~S|;PARAM=VAR;OTHER;OTHER=FOO:VALUE|)
      assert "VALUE" == ICal.Deserialize.skip_params(~S|;PARAM="VAR:":VALUE|)
      assert "VALUE" == ICal.Deserialize.skip_params(~S|;PARAM="VAR:","VAR":VALUE|)
      assert "" == ICal.Deserialize.skip_params(~S|;PARAM="VAR:"|)
      assert "" == ICal.Deserialize.skip_params(~S|;PARAM="VAR:",|)
      assert "" == ICal.Deserialize.skip_params(~S|;PARAM="VAR:","|)
      assert "" == ICal.Deserialize.skip_params(~S|;PARAM="VAR:","F",""|)
    end

    test "Parsing params" do
      assert {"", %{}} == ICal.Deserialize.params("")
      assert {"", %{}} == ICal.Deserialize.params(";")
      assert {"\n", %{}} == ICal.Deserialize.params("\n")
      assert {"\r\n", %{}} == ICal.Deserialize.params("\r\n")
      assert {"VALUE", %{}} == ICal.Deserialize.params(":VALUE")
      assert {"VALUE", %{"P1" => "1"}} == ICal.Deserialize.params(";P1=1:VALUE")

      assert {"VALUE", %{"PARAM" => "VAR:"}} ==
               ICal.Deserialize.params(";PARAM=VAR\\::VALUE")

      assert {"", %{"PARAM" => "VAR"}} ==
               ICal.Deserialize.params(";PARAM=VAR")

      assert {"", %{"PARAM" => "VAR"}} ==
               ICal.Deserialize.params(";PARAM=VAR\r\n")

      assert {"", %{"PARAM" => "VAR"}} ==
               ICal.Deserialize.params(";PARAM=VAR\n")

      assert {"VALUE", %{"PARAM" => "VAR\nfoo"}} ==
               ICal.Deserialize.params(";PARAM=VAR\\nfoo:VALUE")

      assert {"VALUE", %{"PARAM" => "VAR\nfoo"}} ==
               ICal.Deserialize.params(";PARAM=\"VAR\\nfoo\":VALUE")

      assert {"VALUE", %{"P1" => "1", "P2" => "FOO", "OTHER" => ""}} ==
               ICal.Deserialize.params(";P1=1;OTHER;P2=FOO:VALUE")

      assert {"VALUE", %{"P1" => ["1:", ":2", ".."]}} ==
               ICal.Deserialize.params(~S|;P1="1:",":2","..":VALUE|)

      assert {"", %{"P1" => "VAR:\""}} ==
               ICal.Deserialize.params(";P1=\"VAR:\"")

      assert {"", %{"P1" => ""}} == ICal.Deserialize.params(";P1:")
      assert {"VALUE", %{"P1" => ""}} == ICal.Deserialize.params(";P1:VALUE")
      assert {"", %{"P1" => "VAR:\","}} == ICal.Deserialize.params(";P1=\"VAR:\",")
      assert {"", %{"P1" => "VAR:\","}} == ICal.Deserialize.params(";P\\1=\"VAR:\",")
      assert {"", %{"P1" => ["VAR:", ""]}} == ICal.Deserialize.params(";P1=\"VAR:\",\"")

      assert {"", %{"P1" => ["VAR:", "F", "\""]}} ==
               ICal.Deserialize.params(~S|;P1="VAR:","F",""|)
    end

    test "Skip a line" do
      assert "" == ICal.Deserialize.skip_line("")
      assert "" == ICal.Deserialize.skip_line("\n")
      assert "" == ICal.Deserialize.skip_line("\r\n")
      assert "" == ICal.Deserialize.skip_line("foo\r\n")
      assert "bar" == ICal.Deserialize.skip_line("foo\r\nbar")
      assert "bar" == ICal.Deserialize.skip_line("foo\\r\nbar")
    end
  end

  describe "ICal.from_ics/1" do
    test "Single Event" do
      ics = Helper.test_data("one_event")
      %ICal{events: [event]} = ICal.from_ics(ics)

      assert event == Fixtures.one_event()
    end

    test "Single Event from a file" do
      ics = Helper.test_data_path("one_event")
      %ICal{events: [event]} = ICal.from_file(ics)

      assert event == Fixtures.one_event()
    end

    test "Deserializing a non-extant file returns an :error tuple" do
      assert ICal.from_file("/does/not/exist.ics") == {:error, :enoent}
    end

    test "Bad separators do not disturb parsing" do
      ics = Helper.test_data("broken_uid")
      %ICal{events: [event]} = ICal.from_ics(ics)

      assert event == Fixtures.uid_only_event()
    end

    test "Priority must be an integer" do
      ics = Helper.test_data("broken_priority")
      %ICal{events: [event]} = ICal.from_ics(ics)

      assert event == Fixtures.uid_only_event()
    end

    test "Truncated data is handled gracefully" do
      ics = Helper.test_data("truncated_event")
      assert ICal.from_ics(ics) == %ICal{events: [Fixtures.one_truncated_event()]}
    end

    test "Single event with wrapped description and summary" do
      ics = Helper.test_data("one_event_desc_summary")

      %ICal{events: [event]} = ICal.from_ics(ics)

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
      %ICal{events: [event]} = ICal.from_ics(ics)

      # standard timezone
      assert event.dtstart.time_zone == "America/Chicago"

      # olson
      assert event.dtend.time_zone == "America/Chicago"

      # unrecognized tz
      assert event.dtstamp.time_zone == "Etc/UTC"
    end

    test "with CR+LF line endings" do
      ics = Helper.test_data("cr_lf")

      %ICal{events: [event]} = ICal.from_ics(ics)
      assert event.description == "CR+LF line endings"
    end

    test "with URL" do
      ics = Helper.test_data("event_with_url")
      %ICal{events: [event]} = ICal.from_ics(ics)
      assert event.url == "http://google.com"
    end

    test "Event with RECURRENCE-ID in UTC" do
      ics = Helper.test_data("event_with_recurrence_id")
      %ICal{events: [event]} = ICal.from_ics(ics)
      assert event.recurrence_id == ~U[2020-09-17 14:30:00Z]
    end

    test "Event with RECURRENCE-ID with TZID" do
      ics = Helper.test_data("event_with_recurrence_id_tz")
      %ICal{events: [event]} = ICal.from_ics(ics)
      expected = Timex.Timezone.convert(~U[2020-09-17 18:30:00Z], "America/Toronto")
      assert event.recurrence_id == expected
    end

    test "Event with RECURRENCE-ID as DATE" do
      ics = Helper.test_data("event_with_recurrence_id_date")
      %ICal{events: [event]} = ICal.from_ics(ics)
      assert event.recurrence_id == ~U[2020-09-17 00:00:00Z]
    end

    test "Event with attachments" do
      ics = Helper.test_data("attachments")
      %ICal{events: [event]} = ICal.from_ics(ics)
      assert Enum.count(event.attachments) == 5

      [a1, a2, a3, a4, a5] = event.attachments

      # a CID attachment
      assert a1.data_type == :cid
      assert a1.data == "jsmith.part3.960817T083000.xyzMail@example.com"

      # a URL with a mimetype
      assert a2.data_type == :uri
      assert a2.data == "ftp://example.com/pub/reports/r-960812.ps"
      assert a2.mimetype == "application/postscript"
      assert ICal.Attachment.decoded_data(a2) == {:ok, a2.data}

      # an inline 8bit attachment, no mimetype
      assert a3.data_type == :base8
      assert a3.mimetype == nil
      assert a3.data == "Some plain text"

      # an inline base64-encoded attachment with no padding
      assert a4.data_type == :base64
      assert a4.mimetype == "text/plain"

      assert ICal.Attachment.decoded_data(a4) ==
               {:ok, "The quick brown fox jumps over the lazy dog."}

      # an inline base64-encoded attachment with padding
      assert a5.data_type == :base64
      assert {:ok, long_text} = ICal.Attachment.decoded_data(a5)
      assert String.starts_with?(long_text, "Lorem ipsum dolor sit amet,")
      assert String.length(long_text) == 446
      assert a5.mimetype == "text/plain"
    end

    test "Event with attendees" do
      ics = Helper.test_data("attendees")
      %ICal{events: [event]} = ICal.from_ics(ics)
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

    test "Bad dates result in nils" do
      ics = Helper.test_data("broken_dates")
      assert ICal.from_ics(ics) == %ICal{events: [Fixtures.broken_dates_event()]}
    end

    test "Status is properly parsed" do
      ics = Helper.test_data("status")
      assert ICal.from_ics(ics) == Fixtures.statuses()
    end

    test "Transparency is properly parsed" do
      ics = Helper.test_data("transparency")
      assert ICal.from_ics(ics) == Fixtures.transparencies()
    end

    test "Recurrence dates are properly parsed" do
      ics = Helper.test_data("rdates")
      assert ICal.from_ics(ics) == Fixtures.rdates()
    end

    test "Contacts are correctly deserialized" do
      ics = Helper.test_data("contacts")
      assert ICal.from_ics(ics) == Fixtures.contacts()
    end

    test "to_timezone/2 respects default values" do
      assert "Foo/Bar" == ICal.Deserialize.to_timezone(nil, "Foo/Bar")
      assert "Etc/UTC" == ICal.Deserialize.to_timezone(nil)
    end
  end
end
