import Config

if Mix.env() == :dev do
  config :mix_test_watch,
    extra_extensions: [".ics"]
end

if Mix.env() == :dev or Mix.env() == :test do
  config :ical, show_test_timings: false
  config :elixir, :time_zone_database, Tz.TimeZoneDatabase
end
