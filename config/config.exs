import Config

if Enum.member?([:dev, :test], Mix.env()) do
  config :ical, show_test_timings: false
  config :elixir, :time_zone_database, Tz.TimeZoneDatabase
  config :mix_test_watch, extra_extensions: [".ics"]
end
