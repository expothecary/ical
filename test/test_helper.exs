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

  defmacro __using__(_) do
    quote do
      alias ICal.Test.Helper

      def assert_fully_contains(ics, expected) when is_list(ics) do
        ics
        |> to_string()
        |> assert_fully_contains(expected)
      end

      def assert_fully_contains(ics, expected) do
        # since the PRODID changes between versions, just filter that out of both datasets
        ics =
          String.split(ics, "\n", trim: true)
          |> Enum.reject(fn line -> String.starts_with?(line, "PRODID") end)

        lines =
          String.split(expected, "\n", trim: true)
          |> Enum.reject(fn line -> String.starts_with?(line, "PRODID") end)

        reduced =
          Enum.reduce(lines, ics, fn line, ics ->
            index = Enum.find_index(ics, &(line == &1))
            assert index != nil, "Could not find: #{line} in \n#{Enum.join(ics, "\n")}"
            List.delete_at(ics, index)
          end)

        assert reduced == [], "Unexpected lines remaining: \n#{Enum.join(reduced, "\n")}"
      end
    end
  end
end

ExUnit.start()
