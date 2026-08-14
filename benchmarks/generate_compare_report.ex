defmodule BenchmarkReport do
  @default_basepath "benchmarks/results/"

  def pretty_print(opts \\ []) do
    opts
    |> basepath()
    |> Xfile.ls!(show_dirs?: true, recursive: false)
    |> Enum.each(fn path ->
      path
      |> Path.basename()
      |> summarize(opts)
      |> compare()
      |> print_table()
    end)
  end

  defp print_table(results) do
    name_width =
      Enum.reduce(results, 0, fn {name, _tests}, acc ->
        l = String.length(name)
        if l > acc, do: l, else: acc
      end)

    [{_, %{baseline: test_map}} | _] = results

    test_names = to_ordered_list(test_map) |> Enum.map(fn {name, _} -> name end)

    columns =
      Enum.map(test_names, fn name -> String.length(name) + 1 end)
      |> Enum.zip(test_names)

    print_table("vs baseline", name_width, columns, :baseline, results)
    IO.write("\n\n")
    print_table("vs previous", name_width, columns, :previous, results)
  end

  defp print_table(table_name, name_width, columns, test_set, results) do
    name_width = max(String.length(table_name), name_width)

    header =
      Enum.reduce(
        columns,
        "#{String.pad_trailing(table_name, name_width)} ",
        fn {_width, name}, acc ->
          acc <> "| #{name} "
        end
      )

    IO.write(header)
    IO.write("\n")
    IO.write([String.duplicate("-", String.length(header) - 1), "\n"])

    Enum.each(results, fn {name, result} ->
      IO.write(String.pad_leading(name, name_width))
      IO.write(" |")

      results = Map.get(result, test_set)

      Enum.each(columns, fn {width, name} ->
        text =
          case Map.get(results, name) do
            nil ->
              String.pad_leading("", width)

            val ->
              text = String.pad_leading(:erlang.float_to_binary(val, decimals: 2), width)

              cond do
                val < 0.8 -> [:bright, :red, text]
                val < 0.98 -> [:red, text]
                val > 1.5 -> [:bright, :green, text]
                val > 1.02 -> [:green, text]
                true -> text
              end
          end

        Bunt.write(text)
        IO.write(" |")
      end)

      IO.write("\n")
    end)
  end

  defp to_ordered_list(map) do
    map
    |> Enum.to_list()
    |> List.keysort(0)
  end

  defp basepath(opts) do
    Keyword.get(opts, :basepath, @default_basepath)
  end

  def summarize(benchmark, opts \\ []) do
    Bunt.write([:yellow, String.upcase(benchmark), "\n\n"])

    benchmarks_path =
      opts
      |> basepath()
      |> Path.join(benchmark)

    baselines_path = Path.join(benchmarks_path, "baselines")

    baselines =
      baselines_path
      |> Xfile.ls!(recursive: false)
      |> sort_baselines()
      |> Enum.map(&summarize_one/1)

    comparisons =
      benchmarks_path
      |> Xfile.ls!(recursive: false)
      |> Enum.map(&summarize_one/1)

    baselines ++ comparisons
  end

  defp sort_baselines(baselines) do
    Enum.sort(
      baselines,
      fn l, r ->
        :verl.lte(extract_version(l), extract_version(r))
      end
    )
  end

  defp extract_version(path) do
    path
    |> Path.basename()
    |> Path.rootname()
  end

  defp summarize_one(file) do
    key = file |> Path.basename() |> Path.rootname()
    json = file |> File.read!() |> :json.decode()

    results =
      Enum.reduce(json, %{}, fn result, acc ->
        Map.put(acc, result["input_name"], result["run_time_data"]["statistics"]["ips"])
      end)

    {key, results}
  end

  def compare([{_, baseline} | _] = comparisons) do
    compare(baseline, baseline, comparisons, [])
    |> Enum.reverse()
  end

  def compare(_, _, [], acc), do: acc

  def compare(baseline, previous, [{name, current} | next], acc) do
    entry = {
      name,
      %{
        baseline: compare_against(baseline, current),
        previous: compare_against(previous, current)
      }
    }

    compare(
      baseline,
      current,
      next,
      [entry | acc]
    )
  end

  defp compare_against(baseline, comparison) do
    Enum.reduce(comparison, %{}, fn {test, value}, acc ->
      Map.put(acc, test, Float.round(value / Map.get(baseline, test, 1), 2))
    end)
  end
end

BenchmarkReport.pretty_print()
