defmodule ICal do
  @moduledoc """
  The ICal struct which suppports data serialization and deserialization of
  iCalendar data, as well as integration with Plug and Phoenix.
  """

  defstruct product_id: "-//Elixir ICal//v0.1.0//EN",
            scale: "GREGORIAN",
            method: nil,
            version: "2.0",
            events: [],
            default_timezone: "Etc/UTC",
            name: nil,
            custom_properties: %{},
            __other_components: []

  @type custom_value :: %{params: map, value: String.t()}
  @type custom_properties :: %{String.t() => custom_value()}

  @typedoc """
  An iCalendar. Event structs are found in `events`, while vendor-specific
  `X-name`-style entries are recorded in `custom_properties`. All other fields
  conform to the iCalendar standard.
  """
  @type t :: %__MODULE__{
          product_id: String.t() | nil,
          method: String.t() | nil,
          version: String.t(),
          scale: String.t(),
          events: [ICal.Event.t()],
          default_timezone: String.t(),
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
  @spec to_ics(ics_data :: String.t()) :: t()
  defdelegate from_ics(data), to: ICal.Deserialize.Calendar

  @doc """
  Converts the data in the file at `file_path` to an `ICal{}` struct.
  """
  @spec to_ics(file_path :: String.t()) :: t()
  defdelegate from_file(file_path), to: ICal.Deserialize.Calendar

  @doc """
  Allows setting a custom vendor string while maintaiing the rest of the
  default product ID string. This helps identify both the application using
  this library as well as this library when looking at generated output, which
  can be useful for debug purposes.

  As such, this should be prefered to changing the `product_id` field on an
  `%ICal{}` directly.
  """
  def set_vendor(%ICal{} = calendar, vendor) when is_binary(vendor) do
    {:ok, version} = :application.get_key(:ical, :vsn)
    product_id = "-//Elixir ICal//v#{version}//#{vendor}//EN"
    %{calendar | product_id: product_id}
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
end
