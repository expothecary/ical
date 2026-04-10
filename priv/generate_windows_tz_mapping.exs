# This file:
#
# * Fetches the latest list of windows timezones to olson codes from the Unicode repo
# * Parses that file out using Saxy
# * Uses Sourceror to patch the timezone function in-place
#
# Run this with `mix run ./priv/generate_windows_tz_mapping.exs` whenever the list needs
# updating.

defmodule UnicodeTimezones do
  @behaviour Saxy.Handler

  @impl Saxy.Handler
  def handle_event(:start_document, _prolog, _state) do
    {:ok, %{}}
  end

  def handle_event(:end_document, _data, state) do
    {:ok, state}
  end

  @impl Saxy.Handler
  def handle_event(:start_element, {"mapZone", attributes}, %{} = state) do
    # map zone lines have the windows value in "other", and a "teritorry"
    # the teritorry allows mapping a given windows zone to different olson zones
    # depending on the region being referred to.
    #
    # ics data doesn't contain that additional territory information, so we either
    # just use the first entry, or we default to the "ZZ" territory which is the
    # timezone in terms of UTC offset
    non_standard =
      Enum.find_value(
        attributes,
        fn
          {"other", value} -> value
          _ -> false
        end
      )

    standard =
      Enum.find_value(
        attributes,
        fn
          {"type", value} -> value
          _ -> false
        end
      )

    territory =
      Enum.find_value(
        attributes,
        fn
          {"territory", value} -> value
          _ -> false
        end
      )

    state =
      cond do
        not Map.has_key?(state, non_standard) -> Map.put(state, non_standard, standard)
        territory == "ZZ" -> Map.put(state, non_standard, standard)
        true -> state
      end

    {:ok, state}
  end

  def handle_event(:start_element, {_name, _attributes}, %{} = state) do
    {:ok, state}
  end

  @impl Saxy.Handler
  def handle_event(:end_element, _name, state) do
    {:ok, state}
  end

  @impl Saxy.Handler
  def handle_event(:characters, _characters, state) do
    {:ok, state}
  end

  def get_xml() do
    source_of_truth =
      "https://raw.githubusercontent.com/unicode-org/cldr/refs/heads/main/common/supplemental/windowsZones.xml"

    :inets.start()
    :ssl.start()
    {:ok, {_status, _headers, raw_body}} = :httpc.request(source_of_truth)

    raw_body
    |> to_string()
    |> String.trim()
  end

  def update_timezones() do
    # fetch the xml sources from the Unicode github repository
    body = get_xml()

    # parse that XML into a list of windows -> olson zone tuples
    {:ok, result} = Saxy.parse_string(body, __MODULE__, %{})

    list_of_zones =
      result
      |> Map.to_list()
      |> Enum.sort()

    # prepare that list as AST
    new_list_ast =
      "#{inspect(list_of_zones, limit: :infinity)}"
      |> Sourceror.parse_string!()

    # this is where the surgery will happen
    source_path = "lib/ical/deserialize/timezone.ex"

    # to get to the line we wish to replace, read in the file, parse it, open a zipper on it
    # move down into the module contents, find the assignment to `windows_tz`,
    # move down into that node and move to the assigned value.
    # update that value in place with the new list, then run back up to the topmost root,
    # and generate pretty code and write it back out to the source file.
    new_source_code =
      source_path
      |> File.read!()
      |> Sourceror.parse_string!()
      |> Sourceror.Zipper.zip()
      |> Sourceror.Zipper.down()
      |> Sourceror.Zipper.find(fn
        {:=, _, [{:windows_tz, _, _}, {:__block__, _, _}]} -> true
        _ -> false
      end)
      |> Sourceror.Zipper.down()
      |> Sourceror.Zipper.next()
      |> Sourceror.Zipper.update(fn {t, m, _} -> {t, m, [new_list_ast]} end)
      |> Sourceror.Zipper.topmost_root()
      |> Sourceror.to_string()

    File.write!(source_path, new_source_code)
  end
end

UnicodeTimezones.update_timezones()
