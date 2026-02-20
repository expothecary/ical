defmodule ICal.RequestStatusTest do
  use ExUnit.Case

  #   alias ICal.Test.Fixtures
  #   alias ICal.Test.Helper
  alias ICal.Deserialize

  test "Deserializing a request status" do
    assert {"", nil} == Deserialize.RequestStatus.one("")
    assert {"", nil} == Deserialize.RequestStatus.one(";LANGUAGE=de")
    assert {"", nil} == Deserialize.RequestStatus.one(";LANGUAGE=de:")

    assert {"",
            %ICal.RequestStatus{
              code: {2, 0},
              description: "Success",
              exception: nil,
              language: "de"
            }} == Deserialize.RequestStatus.one(";LANGUAGE=de:2.0;Success")

    assert {"",
            %ICal.RequestStatus{
              code: {2, 8},
              description: " Success, repeating event ignored. Scheduled as a single event.",
              exception: "RRULE:FREQ=WEEKLY",
              language: nil
            }} ==
             Deserialize.RequestStatus.one(
               ":2.8; Success\, repeating event ignored. Scheduled as a single event.;RRULE:FREQ=WEEKLY\;INTERVAL=2"
             )

    assert {"",
            %ICal.RequestStatus{
              code: {4, 1},
              description: "Event conflict.  Date-time is busy.",
              exception: nil,
              language: nil
            }} == Deserialize.RequestStatus.one(":4.1;Event conflict.  Date-time is busy.")

    assert {"",
            %ICal.RequestStatus{
              code: {3, 7},
              description: "Invalid calendar user",
              exception: "ATTENDEE:mailto:jsmith@example.com",
              language: nil
            }} ==
             Deserialize.RequestStatus.one(
               ";OTHER=PARAM:3.7;Invalid calendar user;ATTENDEE:mailto:jsmith@example.com"
             )

    assert {"",
            %ICal.RequestStatus{
              code: {3, 1},
              description: "Invalid property value",
              exception: "DTSTART:96-Apr-01",
              language: nil
            }} == Deserialize.RequestStatus.one(":3.1;Invalid property value;DTSTART:96-Apr-01")


    assert {"Next Line",
            %ICal.RequestStatus{
              code: {3, 1},
              description: "Invalid property value",
              exception: "DTSTART:96-Apr-01;",
              language: nil
            }} == Deserialize.RequestStatus.one(":3.1;Invalid property \\value;DTSTART:96-Apr-01\\;\nNext Line")
  end

  test "Serializing a request status" do
  end
end
