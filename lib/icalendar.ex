defmodule ICalendar do
  @moduledoc """
  ICalendar struct that suppports data serialization and deserialization,
  as well as integration with Plug and Phoenix.
  """

  defstruct product_id: "-//Elixir ICalendar//EN",
            scale: "GREGORIAN",
            method: nil,
            version: "2.0",
            events: [],
            default_timezone: nil,
            custom_entries: %{}

  @type custom_value :: %{params: map, value: String.t()}
  @type custom_entries :: %{String.t() => custom_value()}
  @type t :: %__MODULE__{
          product_id: String.t() | nil,
          method: String.t() | nil,
          version: String.t(),
          scale: String.t(),
          events: [ICalendar.Event.t()],
          default_timezone: String.t() | nil,
          custom_entries: custom_entries
        }

  defdelegate to_ics(calendar), to: ICalendar.Serialize.Calendar
  defdelegate from_ics(data), to: ICalendar.Deserialize.Calendar
  defdelegate from_file(path), to: ICalendar.Deserialize.Calendar

  def set_vendor(%ICalendar{} = calendar, vendor) when is_binary(vendor) do
    %{calendar | product_id: "-//Elixir ICalendar//#{vendor}//EN"}
  end

  @doc """
  To create a Phoenix/Plug controller and view that output ics format:

  Add to your config.exs:

      config :phoenix, :format_encoders,
        ics: ICalendar

  In your controller use:

      calendar = %ICalendar{ events: events }
      render(conn, "index.ics", calendar: calendar)

  The important part here is `.ics`. This triggers the `format_encoder`
  as configured.

  In your view can put:

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
