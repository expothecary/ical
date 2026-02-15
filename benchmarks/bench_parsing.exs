IO.puts("FILE UNDER TEST: #{System.get_env("ICS_PATH")}")

ics =
  System.get_env("ICS_PATH")
  |> File.read!()

Benchee.run(
  %{
    "parsinng ICS data" => {
      fn _ -> ICal.from_ics(ics) end,
      before_scenario: fn flags ->
        Enum.each(flags, fn {flag, value} -> Application.put_env(:ical, flag, value) end)
      end
    }
  },
  inputs: %{
    "baseline" => %{},
    "experiment" => %{}
  },
  warmup: 4,
  time: 4,
  memory_time: 1
)
