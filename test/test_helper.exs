defmodule ICal.Test.Helper do
  def test_data_path(name) do
    Path.join([File.cwd!(), "/test/data"], name <> ".ics")
  end

  def test_data(name) do
    name
    |> test_data_path()
    |> File.read!()
  end

  def product_id do
    {:ok, version} = :application.get_key(:ical, :vsn)
    "-//Elixir ICal//v#{version}//EN"
  end

  def product_id(custom_vendor) do
    {:ok, version} = :application.get_key(:ical, :vsn)
    "-//Elixir ICal//v#{version}//#{custom_vendor}//EN"
  end

  def extract_event_props(["BEGIN:VEVENT\n", props, "END:VEVENT\n"]) do
    ["BEGIN:VEVENT\n", Enum.sort(props), "END:VEVENT\n"] |> to_string()
  end

  def extract_event_props(ics) do
    Enum.reduce(ics, [], fn
      ["BEGIN:VEVENT\n", props, "END:VEVENT\n"], acc ->
        acc ++ ["BEGIN:VEVENT\n", Enum.sort(props), "END:VEVENT\n"]

      _, acc ->
        acc
    end)
    |> to_string()
  end
end

ExUnit.start()
