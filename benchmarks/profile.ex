defmodule ICalProfiling do
  def large_recurrence do
    dtstart_ics = "DTSTART;TZID=America/Chicago:20230221T235900"
    {_, %ICal.Event{dtstart: dtstart}} = ICal.Deserialize.Event.one(dtstart_ics, %ICal{})

    rule =
      ICal.Recurrence.from_ics(
        "RRULE:FREQ=MONTHLY;COUNT=480;INTERVAL=1;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=1,-1"
      )

    ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.to_list()
  end

  def daily_recurrence do
    dtstart_ics = "DTSTART;TZID=America/Chicago:20230221T235900"
    {_, %ICal.Event{dtstart: dtstart}} = ICal.Deserialize.Event.one(dtstart_ics, %ICal{})

    rule =
      ICal.Recurrence.from_ics("RRULE:FREQ=DAILY;COUNT=30;INTERVAL=1")

    ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.to_list()
  end

  def weekdays_recurrence do
    dtstart_ics = "DTSTART;TZID=America/Chicago:20230221T235900"
    {_, %ICal.Event{dtstart: dtstart}} = ICal.Deserialize.Event.one(dtstart_ics, %ICal{})

    rule =
      ICal.Recurrence.from_ics("RRULE:FREQ=DAILY;COUNT=520;INTERVAL=1;BYDAY=MO,TU,WE,TH,FR")

    ICal.Recurrence.stream(rule, start_date: dtstart) |> Enum.to_list()
  end

  def profile do
    :dbg.start()
    :fprof.start()

    for {name, func} <- [
          #           {"recurence_large", &large_recurrence/0},
          {"recurrence_common", &daily_recurrence/0}
        ] do
      analysis_name = "profile_#{name}.analysis"
      cgrind_name = "profile_#{name}.cachegrind"
      :fprof.trace([:start, procs: [self()]])

      Enum.each(1..1000, fn _ -> func.() end)

      :fprof.trace(:stop)
      :fprof.profile()
      :fprof.analyse(totals: false, dest: String.to_charlist(analysis_name))
      System.cmd("erlgrind", [analysis_name, cgrind_name])
    end

    :fprof.stop()
  end
end

Enum.each(1..10, fn _ -> ICalProfiling.weekdays_recurrence() end)
