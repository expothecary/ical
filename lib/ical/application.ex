defmodule ICal.Application do
  @moduledoc false

  use Application
  require Logger

  @impl Application
  def start(_type, _args) do
    Calendar.get_time_zone_database()
    |> check_timezone_availability()

    Supervisor.start_link([], strategy: :one_for_one, name: ICal.Application)
  end

  defp check_timezone_availability(Calendar.UTCOnlyTimeZoneDatabase) do
    cond do
      Code.ensure_loaded?(Tz) ->
        Logger.info(
          "ICal has registered the Tz time zone database to ensure full function. Consider adding this to your app config: config :elixir, :time_zone_database, Tz.TimeZoneDatabase"
        )

        Calendar.put_time_zone_database(Tz.TimeZoneDatabase)
        :ok

      Code.ensure_loaded?(TimeZoneInfo) ->
        Logger.info(
          "ICal has registered the TimeZoneInfo time zone database to ensure full function. Consider adding this to your app config: config :elixir, :time_zone_database, TimeZoneInfo.TimeZoneDatabase"
        )

        Calendar.put_time_zone_database(TimeZoneInfo.TimeZoneDatabase)
        :ok

      true ->
        Logger.error(
          "No timezone database is instealled, and neither the Tz nor TimeZoneInfo libraries wer found. Please install one of those as per the ICal documentation to ensure that ICal works correctly. Without a timezone database, no calendaring data with timezones will parse correctly."
        )
    end
  end

  # there is a non-default timezone database installed, so ICal is good to go.
  defp check_timezone_availability(_), do: :ok
end
