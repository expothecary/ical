IO.puts("FILE UNDER TEST: #{System.get_env("ICS_PATH")}")

ics =
  System.get_env("ICS_PATH")
  |> File.read!()

Benchee.run(
  %{
    "ICal" => fn -> ICal.from_ics(ics) end
  },
  warmup: 3,
  time: 4,
  memory_time: 2
)
