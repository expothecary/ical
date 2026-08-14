parse_dtstart = fn ics ->
  {_, %ICal.Event{dtstart: dtstart}} = ICal.Deserialize.Event.one(ics, %ICal{})
  dtstart
end

inputs = %{
  daily_30: %{
    label: "30 daily occurrences",
    description: "Equivalent to the published rrule-rust benchmark case.",
    expectedCount: 30,
    dtstart: parse_dtstart.("DTSTART;TZID=America/Chicago:20230221T235900"),
    rrule: ICal.Recurrence.from_ics("RRULE:FREQ=DAILY;COUNT=30;INTERVAL=1") |> IO.inspect()
  },
  daily_weekdays_520: %{
    label: "Daily weekdays across many cycles",
    description: "520 weekday-only daily occurrences.",
    expectedCount: 520,
    dtstart: parse_dtstart.("DTSTART;TZID=America/Chicago:20230221T235900"),
    rrule: ICal.Recurrence.from_ics("RRULE:FREQ=DAILY;COUNT=520;INTERVAL=1;BYDAY=MO,TU,WE,TH,FR")
  },
  hourly_720: %{
    label: "720 hourly occurrences",
    description: "Simple hourly frequency across 30 days.",
    expectedCount: 720,
    dtstart: parse_dtstart.("DTSTART;TZID=America/Chicago:20230121T235900"),
    rrule: ICal.Recurrence.from_ics("RRULE:FREQ=HOURLY;COUNT=720;INTERVAL=1")
  },
  minutely_1440: %{
    label: "1,440 minutely occurrences",
    description: "Simple minutely frequency across 24 hours.",
    expectedCount: 1440,
    dtstart: parse_dtstart.("DTSTART;TZID=America/Chicago:20230221T235900"),
    rrule: ICal.Recurrence.from_ics("RRULE:FREQ=MINUTELY;COUNT=1440;INTERVAL=1")
  },
  weekly_mwf_780: %{
    label: "Weekly MO/WE/FR across many cycles",
    description: "780 occurrences over roughly 5 years.",
    expectedCount: 780,
    dtstart: parse_dtstart.("DTSTART;TZID=America/Chicago:20230221T235900"),
    rrule: ICal.Recurrence.from_ics("RRULE:FREQ=WEEKLY;COUNT=780;INTERVAL=1;BYDAY=MO,WE,FR")
  },
  monthly_last_weekday_240: %{
    label: "Monthly last weekday across 20 years",
    description: "240 occurrences using BYDAY + BYSETPOS=-1.",
    expectedCount: 240,
    dtstart: parse_dtstart.("DTSTART;TZID=America/Chicago:20230221T235900"),
    rrule:
      ICal.Recurrence.from_ics(
        "RRULE:FREQ=MONTHLY;COUNT=240;INTERVAL=1;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1"
      )
  },
  monthly_first_last_weekday_480: %{
    label: "Monthly first and last weekday across 20 years",
    description: "480 occurrences using BYDAY + BYSETPOS=1,-1.",
    dtstart: parse_dtstart.("DTSTART;TZID=America/Chicago:20230221T235900"),
    rrule:
      ICal.Recurrence.from_ics(
        "RRULE:FREQ=MONTHLY;COUNT=480;INTERVAL=1;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=1,-1"
      )
  }
}

File.mkdir_p("benchmarks/results")

Benchee.run(
  %{
    "recurrence stream" => fn input ->
      ICal.Recurrence.stream(input.rrule, start_date: input.dtstart) |> Enum.to_list()
    end
  },
  inputs: inputs,
  warmup: 4,
  time: 4,
  memory_time: 1,
  formatters: [
    {Benchee.Formatters.JSON,
     file: "benchmarks/results/recurrences/#{DateTime.to_iso8601(DateTime.utc_now())}.json"},
    Benchee.Formatters.Console
  ]
)
