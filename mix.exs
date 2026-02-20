defmodule ICal.Mixfile do
  use Mix.Project

  @source_url "https://github.com/expothecary/ical"
  @version "1.1.0"

  def project do
    [
      app: :ical,
      name: "iCal",
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      preferred_cli_env: cli(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support", "test/data"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:timex, "~> 3.4"},
      {:mix_test_watch, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: :test, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev, :test], runtime: false},

      # benchmarking...
      {:benchee, "~> 1.0", only: [:dev, :test]}
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.github": :test,
        "coveralls.html": :test,
        "test.watch": :test
      ]
    ]
  end

  defp package do
    [
      description: "iCalendar support with a focus on real-world usage and good DevEx",
      maintainers: ["Max Salminen", "Aaron Seigo"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "https://hexdocs.pm/ical/changelog.html",
        "GitHub" => @source_url
      }
    ]
  end

  defp docs do
    [
      extras: ["CHANGELOG.md", "README.md"],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"],
      groups_for_modules: [
        "Calendar Entries": [ICal.Alarm, ICal.Event, ICal.Timezone],
        Properties: [
          ICal.Attachment,
          ICal.Attendee,
          ICal.Contact,
          ICal.Duration,
          ICal.Timezone.Properties
        ],
        Alarms: [~r/ICal.Alarm.*/],
        Utilities: [ICal.Recurrence]
      ]
    ]
  end
end
