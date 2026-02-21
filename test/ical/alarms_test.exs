defmodule ICalTest.Alarms do
  use ExUnit.Case

  alias ICal.Test.Fixtures
  use ICal.Test.Helper

  test "Deserializing an event with alarms" do
    ics = Helper.test_data("event_with_alarms")

    expected =
      "BEGIN:VEVENT\nBEGIN:VALARM\nREPEAT:4\nTRIGGER:19970317T133000Z\nACTION:AUDIO\nATTACH;FMTTYPE=audio/basic:ftp://example.com/pub/sounds/bell-01.aud\nDURATION:PT15M\nEND:VALARM\nBEGIN:VALARM\nREPEAT:4\nTRIGGER:19970317T133000Z\nACTION:AUDIO\nATTACH;FMTTYPE=audio/basic:ftp://example.com/pub/sounds/bell-01.aud\nEND:VALARM\nBEGIN:VALARM\nREPEAT:2\nTRIGGER:-PT30M\nACTION:DISPLAY\nDESCRIPTION:Breakfast meeting with executive\\nteam at 8:30 AM EST.\nEND:VALARM\nBEGIN:VALARM\nTRIGGER;RELATED:END:-P2D\nACTION:EMAIL\nATTENDEE:mailto:john_doe@example.com\nATTACH;FMTTYPE=application/msword:http://example.com/templates/agenda.doc\nDESCRIPTION:A draft agenda needs to be sent out to the attendees to the weekly managers meeting (MGR-LIST). Attached is a pointer the document template for the agenda file.\nSUMMARY:*** REMINDER: SEND AGENDA FOR WEEKLY STAFF MEETING ***\nEND:VALARM\nBEGIN:VALARM\nTRIGGER;RELATED:START:P2D\nACTION:DISPLAY\nDESCRIPTION:BOINK\nX-Extra:Yep\nEND:VALARM\nBEGIN:VALARM\nTRIGGER:\nACTION:SomethingUnique\nEND:VALARM\nDTSTAMP:20260217T215102Z\nDTSTART:20200917T143000Z\nUID:1\nEND:VEVENT\n"

    {_, event} = ICal.Deserialize.Event.one(ics, %ICal{})
    assert Enum.count(event.alarms) == 6

    [alarm1, alarm2, alarm3, alarm4, alarm5, alarm6] = event.alarms

    assert Fixtures.alarm(:audio) == alarm1

    assert Fixtures.alarm(:audio_no_duration) == alarm2
    assert Fixtures.alarm(:display) == alarm3
    assert Fixtures.alarm(:email) == alarm4
    assert Fixtures.alarm(:display_start) == alarm5
    assert Fixtures.alarm(:custom) == alarm6

    event
    |> ICal.Serialize.Event.component()
    |> assert_fully_contains(expected)
  end

  test "Alarm.one/2 handles premature end of date" do
    assert {<<>>, nil} == ICal.Deserialize.Alarm.one(<<>>, %ICal{})
  end
end
