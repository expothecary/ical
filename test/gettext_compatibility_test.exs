defmodule ICal.GettextCompatibilityTest do
  use ExUnit.Case
  use ICal.Test.Helper

  describe "gettext 1.0.x compatibility" do
    test "gettext is resolved to a compatible version" do
      {:ok, version} = :application.get_key(:gettext, :vsn)
      version_string = List.to_string(version)
      [major | _] = version_string |> String.split(".") |> Enum.map(&String.to_integer/1)

      assert major in [0, 1],
             "expected gettext 0.26.x or 1.0.x, got #{version_string}"
    end

    test "timex date formatting works through gettext dependency" do
      dt = Timex.to_datetime({{2025, 6, 15}, {14, 30, 0}})

      {:ok, formatted} = Timex.format(dt, "{YYYY}{0M}{0D}T{h24}{m}{s}")
      assert formatted == "20250615T143000"

      {:ok, formatted} = Timex.format(dt, "{ISO:Extended}")
      assert formatted == "2025-06-15T14:30:00+00:00"
    end

    test "timex timezone conversion works through gettext dependency" do
      utc_dt = ~U[2025-06-15 14:30:00Z]
      toronto_dt = Timex.Timezone.convert(utc_dt, "America/Toronto")

      assert toronto_dt.time_zone == "America/Toronto"
      assert toronto_dt.hour == 10
    end

    test "full ICS round-trip with timezone-aware dates works" do
      events = [
        %ICal.Event{
          summary: "Gettext compat test",
          dtstart: Timex.to_datetime({{2025, 6, 15}, {14, 30, 0}}),
          dtstamp: Timex.to_datetime({{2025, 6, 15}, {8, 0, 0}}),
          dtend: Timex.to_datetime({{2025, 6, 15}, {15, 30, 0}}),
          description: "Testing gettext compatibility"
        }
      ]

      ics = %ICal{events: events} |> ICal.to_ics() |> to_string()

      assert ics =~ "DTSTART:20250615T143000Z"
      assert ics =~ "DTEND:20250615T153000Z"

      %ICal{events: [parsed_event]} = ICal.from_ics(ics)
      assert parsed_event.summary == "Gettext compat test"
    end

    test "ICS round-trip with non-UTC timezone works" do
      recurrence_id = Timex.Timezone.convert(~U[2025-06-15 18:30:00Z], "America/Toronto")

      events = [
        %ICal.Event{
          recurrence_id: recurrence_id,
          summary: "Modified instance"
        }
      ]

      ics = %ICal{events: events} |> ICal.to_ics() |> to_string()

      assert ics =~ "RECURRENCE-ID;TZID=America/Toronto:20250615T143000"
    end

    test "Gettext.put_locale!/2 is available for gettext >= 1.0.0" do
      {:ok, version} = :application.get_key(:gettext, :vsn)
      version_string = List.to_string(version)
      [major | _] = version_string |> String.split(".") |> Enum.map(&String.to_integer/1)

      if major >= 1 do
        assert function_exported?(Gettext, :put_locale!, 2),
               "Gettext.put_locale!/2 should be exported in gettext #{version_string}"
      end
    end
  end
end
