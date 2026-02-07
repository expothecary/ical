defmodule ICalendar.Mixfile do
  use Mix.Project

  @source_url "https://github.com/expothecary/icalendar"
  @version "1.2.0"

  def project do
    [
      app: :icalendar,
      name: "ICalendar",
      version: @version,
      elixir: "~> 1.15",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      preferred_cli_env: cli(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  defp deps do
    [
      {:timex, "~> 3.4"},
      {:mix_test_watch, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.14", only: :test, runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev, :test], runtime: false}
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.github": :test,
        "test.watch": :test
      ]
    ]
  end

  defp package do
    [
      description: "ICalendar data consumer and generator",
      maintainers: ["Max Salminen", "Aaron Seigo"],
      licenses: ["MIT"],
      links: %{
        "Changelog" => "https://hexdocs.pm/icalendar/changelog.html",
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
      formatters: ["html"]
    ]
  end
end
