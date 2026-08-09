defmodule ICal.AvailabilityTest do
  use ExUnit.Case

  use ICal.Test.Helper

  alias ICal.Availability

  defp availability(name) do
    name
    |> Helper.test_data()
    |> ICal.from_ics()
  end

  describe "deserializing VAVAILABILITY" do
    test "the component is collected onto the calendar" do
      calendar = availability("availability")

      assert [%Availability{} = one] = calendar.availabilities
      assert one.uid == "0428C7D2-688E-4D2E-AC52-CD112E2469DF"
    end

    test "it does not disturb the other component lists" do
      calendar = availability("availability")

      assert calendar.events == []
      assert calendar.todos == []
      assert calendar.journals == []
    end

    test "the bounding period is read" do
      [one] = availability("availability").availabilities

      assert one.dtstart == ~U[2011-10-02 00:00:00Z]
      assert one.dtend == ~U[2011-10-23 00:00:00Z]
      assert one.dtstamp == ~U[2011-10-05 13:32:25Z]
    end

    test "shared properties come through the component macros" do
      [one] = availability("availability").availabilities

      assert one.summary == "Office hours"
      assert one.organizer == "mailto:bernard@example.com"
    end
  end

  describe "BUSYTYPE" do
    test "an explicit value is read" do
      [one] = availability("availability").availabilities

      assert one.busytype == :busy_unavailable
    end

    test "it defaults to BUSY-UNAVAILABLE when absent, per RFC 7953" do
      ics = """
      BEGIN:VCALENDAR
      VERSION:2.0
      BEGIN:VAVAILABILITY
      UID:no-busytype
      DTSTAMP:20111005T133225Z
      END:VAVAILABILITY
      END:VCALENDAR
      """

      assert [one] = ICal.from_ics(ics).availabilities
      assert one.busytype == :busy_unavailable
    end

    test "each defined value maps to its atom" do
      for {token, expected} <- [
            {"BUSY", :busy},
            {"BUSY-UNAVAILABLE", :busy_unavailable},
            {"BUSY-TENTATIVE", :busy_tentative}
          ] do
        ics = """
        BEGIN:VCALENDAR
        VERSION:2.0
        BEGIN:VAVAILABILITY
        UID:busytype-#{token}
        DTSTAMP:20111005T133225Z
        BUSYTYPE:#{token}
        END:VAVAILABILITY
        END:VCALENDAR
        """

        assert [one] = ICal.from_ics(ics).availabilities
        assert one.busytype == expected
      end
    end

    test "an extension token is kept verbatim rather than dropped" do
      ics = """
      BEGIN:VCALENDAR
      VERSION:2.0
      BEGIN:VAVAILABILITY
      UID:extension-busytype
      DTSTAMP:20111005T133225Z
      BUSYTYPE:X-OUT-OF-OFFICE
      END:VAVAILABILITY
      END:VCALENDAR
      """

      assert [one] = ICal.from_ics(ics).availabilities
      assert one.busytype == "X-OUT-OF-OFFICE"
    end
  end

  describe "AVAILABLE subcomponents" do
    test "one is nested under its parent, not hoisted to the calendar" do
      [one] = availability("availability").availabilities

      assert [available] = one.available
      assert available.uid == "34EDA59B-6BB1-4E94-A66C-64999089C0AF"
    end

    test "its own period and text are read" do
      [%{available: [available]}] = availability("availability").availabilities

      assert available.dtstart == ~U[2011-10-02 09:00:00Z]
      assert available.dtend == ~U[2011-10-02 17:00:00Z]
      assert available.summary == "Monday to Friday from 9:00 to 17:00"
      assert available.location == "Main Office"
    end

    test "a recurrence rule is parsed into a Recurrence" do
      [%{available: [available]}] = availability("availability").availabilities

      assert %ICal.Recurrence{} = available.rrule
      assert available.rrule.frequency == :weekly
    end

    test "several subcomponents are kept in order" do
      [_first, second] = availability("availability_priority").availabilities

      assert length(second.available) == 2

      assert Enum.map(second.available, & &1.summary) == [
               "Monday to Thursday from 9:00 to 17:00",
               "Friday mornings only"
             ]
    end

    test "DURATION is read as an alternative to DTEND" do
      [_first, second] = availability("availability_priority").availabilities
      [_weekdays, friday] = second.available

      assert friday.dtend == nil
      assert %ICal.Duration{} = friday.duration
    end

    test "EXDATE is collected" do
      [_first, second] = availability("availability_priority").availabilities
      [_weekdays, friday] = second.available

      assert friday.exdates == [~U[2011-11-25 10:00:00Z]]
    end
  end

  describe "several VAVAILABILITY components" do
    test "each is collected" do
      calendar = availability("availability_priority")

      assert length(calendar.availabilities) == 2
    end

    test "PRIORITY distinguishes them" do
      [first, second] = availability("availability_priority").availabilities

      assert first.priority == 1
      assert second.priority == 2
    end

    test "priority is nil when unstated, ranking below all of them" do
      [one] = availability("availability").availabilities

      assert one.priority == nil
    end

    test "an unbounded end is nil rather than invented" do
      [_first, second] = availability("availability_priority").availabilities

      assert second.dtstart == ~U[2011-10-23 00:00:00Z]
      assert second.dtend == nil
    end
  end

  describe "VAVAILABILITY alongside other components" do
    test "an event in the same calendar still parses" do
      ics = """
      BEGIN:VCALENDAR
      VERSION:2.0
      BEGIN:VAVAILABILITY
      UID:availability-1
      DTSTAMP:20111005T133225Z
      BEGIN:AVAILABLE
      UID:available-1
      DTSTAMP:20111005T133225Z
      DTSTART:20111002T090000Z
      DTEND:20111002T170000Z
      END:AVAILABLE
      END:VAVAILABILITY
      BEGIN:VEVENT
      UID:event-1
      DTSTAMP:20111005T133225Z
      DTSTART:20111002T100000Z
      DTEND:20111002T110000Z
      SUMMARY:A meeting
      END:VEVENT
      END:VCALENDAR
      """

      calendar = ICal.from_ics(ics)

      assert [%{uid: "availability-1"}] = calendar.availabilities
      assert [%{uid: "event-1", summary: "A meeting"}] = calendar.events
    end

    test "an empty buffer yields nil, as for every other component" do
      assert {"", nil} == ICal.Deserialize.Availability.one("", %ICal{})
      assert {"", nil} == ICal.Deserialize.Availability.one("\r\n", %ICal{})
      assert {"", nil} == ICal.Deserialize.Availability.one("\n", %ICal{})
    end

    test "a VAVAILABILITY with no AVAILABLE subcomponents is still valid" do
      ics = """
      BEGIN:VCALENDAR
      VERSION:2.0
      BEGIN:VAVAILABILITY
      UID:busy-all-week
      DTSTAMP:20111005T133225Z
      DTSTART:20111002T000000Z
      DTEND:20111009T000000Z
      END:VAVAILABILITY
      END:VCALENDAR
      """

      assert [one] = ICal.from_ics(ics).availabilities
      assert one.available == []
    end
  end

  describe "serializing" do
    test "a round trip preserves the component" do
      original = availability("availability")

      reparsed =
        original
        |> ICal.to_ics()
        |> to_string()
        |> ICal.from_ics()

      assert reparsed.availabilities == original.availabilities
    end

    test "a round trip preserves several components and their subcomponents" do
      original = availability("availability_priority")

      reparsed =
        original
        |> ICal.to_ics()
        |> to_string()
        |> ICal.from_ics()

      assert reparsed.availabilities == original.availabilities
    end

    test "the emitted component is well formed" do
      ics =
        %ICal{
          availabilities: [
            %Availability{
              uid: "emitted-1",
              dtstamp: ~U[2011-10-05 13:32:25Z],
              busytype: :busy,
              available: [
                %Availability.Available{
                  uid: "emitted-available-1",
                  dtstamp: ~U[2011-10-05 13:32:25Z],
                  dtstart: ~U[2011-10-02 09:00:00Z],
                  dtend: ~U[2011-10-02 17:00:00Z]
                }
              ]
            }
          ]
        }
        |> ICal.to_ics()
        |> to_string()

      assert ics =~ "BEGIN:VAVAILABILITY"
      assert ics =~ "END:VAVAILABILITY"
      assert ics =~ "BEGIN:AVAILABLE"
      assert ics =~ "END:AVAILABLE"
      assert ics =~ "BUSYTYPE:BUSY"
      assert ics =~ "UID:emitted-1"
      assert ics =~ "UID:emitted-available-1"
    end

    test "an extension busytype survives a round trip" do
      original = %ICal{
        availabilities: [
          %Availability{
            uid: "x-busytype",
            dtstamp: ~U[2011-10-05 13:32:25Z],
            busytype: "X-OUT-OF-OFFICE"
          }
        ]
      }

      reparsed = original |> ICal.to_ics() |> to_string() |> ICal.from_ics()

      assert [%{busytype: "X-OUT-OF-OFFICE"}] = reparsed.availabilities
    end
  end
end
