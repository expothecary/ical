defmodule ICal do
  @moduledoc """
  The ICal struct which suppports data serialization and deserialization of
  iCalendar data, as well as integration with Plug and Phoenix.
  """

  defstruct product_id: nil,
            scale: "GREGORIAN",
            method: nil,
            version: "2.0",
            events: [],
            todos: [],
            journals: [],
            availabilities: [],
            timezones: %{},
            default_timezone: nil,
            name: nil,
            custom_properties: %{},
            __other_components: []

  @typedoc "ICalendar datetimes, which may have a timezone or be floating"
  @type rfc5455_datetime :: DateTime.t() | NaiveDateTime.t()
  @typedoc "Optional ICalendar datetimes"
  @type optional_rfc5455_datetime :: rfc5455_datetime | nil
  @typedoc "ICalendar dates, which may be simple dates or have time with a timezone or floating"
  @type rfc5455_date :: Date.t() | rfc5455_datetime
  @typedoc "Optional ICalendar dates"
  @type optional_rfc5455_date :: rfc5455_date | nil

  @type custom_value :: %{params: map, value: String.t()}
  @type custom_properties :: %{String.t() => custom_value()}
  @type geo :: {float, float}
  @type period ::
          {from :: DateTime.t(), to :: DateTime.t()}
          | {from :: DateTime.t(), to :: ICal.Duration.t()}

  @typedoc """
  An iCalendar. Event structs are found in `events`, while vendor-specific
  `X-name`-style entries are recorded in `custom_properties`. All other fields
  conform to the iCalendar standard.

  Timezones are stored by their ID for convenient lookup as needed.
  """
  @type t :: %__MODULE__{
          product_id: String.t() | nil,
          method: String.t() | nil,
          version: String.t(),
          scale: String.t(),
          events: [ICal.Event.t()],
          todos: [ICal.Todo.t()],
          journals: [ICal.Journal.t()],
          availabilities: [ICal.Availability.t()],
          timezones: %{String.t() => ICal.Timezone.t()},
          default_timezone: String.t() | nil,
          name: String.t() | nil,
          custom_properties: custom_properties
        }

  @doc """
  Converts an `ICal{}` struct to `iodata`.

  The returned iodata can be written directly to a file, sent across the network,
  or turned into a string locally by passing the return value to `to_string/1`
  """
  @spec to_ics(t()) :: iolist()
  defdelegate to_ics(calendar), to: ICal.Serialize.Calendar

  @doc """
  Converts a string containing iCalendar data to an `ICal{}` struct.
  """
  @spec from_ics(ics_data :: String.t()) :: t()
  defdelegate from_ics(data), to: ICal.Deserialize.Calendar

  @doc """
  Converts the data in the file at `file_path` to an `ICal{}` struct.
  """
  @spec from_file(file_path :: String.t()) :: t()
  defdelegate from_file(file_path), to: ICal.Deserialize.Calendar

  @doc """
  Allows setting a custom vendor string while maintaiing the rest of the
  default product ID string. This helps identify both the application using
  this library as well as this library when looking at generated output, which
  can be useful for debug purposes.

  As such, this should be prefered to changing the `product_id` field on an
  `%ICal{}` directly.
  """
  @spec set_vendor(t(), vendor :: String.t()) :: t()
  def set_vendor(%ICal{} = calendar, vendor) when is_binary(vendor) do
    {:ok, version} = :application.get_key(:ical, :vsn)
    product_id = "-//Elixir ICal//v#{version}//#{vendor}//EN"
    %{calendar | product_id: product_id}
  end

  @doc """
  Returns the default product ID for calendars generated with the ICal library.
  To customize this, either set the `produdct_id` on an `%ICal{}` struct before
  serializing it with `to_ics`, or use the `set_vendor/2` convenience function.
  """
  def default_product_id do
    {:ok, version} = :application.get_key(:ical, :vsn)
    "-//Elixir ICal//v#{version}//EN"
  end

  @doc """
  To create a Phoenix/Plug endpoint to retrieve ICal data from,
  add this to the application's `config.exs`:

      config :phoenix, :format_encoders, ics: ICal

  Adding this to a controller will trigger the serialization to occur:

      calendar = %ICal{ events: events }
      render(conn, "index.ics", calendar: calendar)

  The file suffix `.ics` triggers the `format_encoder` as configured.

  The same in a view:

      def render("index.ics", %{calendar: calendar}) do
        calendar
      end

  """
  def encode_to_iodata(calendar, options \\ []) do
    {:ok, encode_to_iodata!(calendar, options)}
  end

  def encode_to_iodata!(calendar, _options \\ []) do
    to_ics(calendar)
  end

  @doc false
  @spec as_valid_datetime(Date.t(), Time.t(), timezone :: String.t()) :: DateTime.t() | nil
  def as_valid_datetime(date, time, timezone) do
    # RFC 5545 §3.3.5 defines how DST edge cases should be handled:
    #
    # Ambiguous (fall-back, clocks go back — time occurs twice): "the
    # DATE-TIME value refers to the first occurrence of the referenced
    # time." The first occurrence is the daylight (pre-transition) instant.
    #
    # Gap (spring-forward, clocks go forward — time never exists): "the
    # DATE-TIME value is interpreted using the UTC offset before the gap."
    # e.g. 2:30 AM in a spring-forward gap → apply pre-gap offset (EST) to
    # get UTC, then express in the post-gap offset (EDT) → 3:30 AM EDT.
    case DateTime.new(date, time, timezone) do
      {:ok, dt} -> dt
      {:ambiguous, first, _second} -> first
      {:gap, just_before, just_after} -> adjust_to_gap(time, just_before, just_after)
      _ -> nil
    end
  rescue
    _ -> nil
  end

  defp adjust_to_gap(original_time, before_gap, after_gap) do
    before_gap =
      before_gap
      |> DateTime.to_time()
      |> round_off_micros()

    diff = Time.diff(original_time, before_gap)

    time = Time.shift(DateTime.to_time(after_gap), second: diff)

    DateTime.new!(DateTime.to_date(after_gap), time, after_gap.time_zone)
  end

  defp round_off_micros(time) do
    # gap times are often 59.9999 seconds, the moment RIGHT before.
    # snug those times up to the minute
    {ms, precision} = time.microsecond
    offset = round(ms / Integer.pow(10, precision))

    time
    |> Time.truncate(:second)
    |> Time.shift(second: offset)
  end
end
