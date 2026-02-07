defmodule ICalendar do
  @moduledoc """
  Generating ICalendars.
  """

  defstruct product_id: "-//Elixir ICalendar//EN",
            scale: "GREGORIAN",
            method: nil,
            version: "2.0",
            events: []

  @type t :: %__MODULE__{
          product_id: String.t() | nil,
          method: String.t() | nil,
          version: String.t(),
          scale: String.t(),
          events: [ICalendar.Event.t()]
        }

  defdelegate to_ics(events), to: ICalendar.Serialize
  defdelegate from_ics(events), to: ICalendar.Deserialize

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

  The important part here is `.ics`. This triggers the `format_encoder`.

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

defimpl ICalendar.Serialize, for: ICalendar do
  def to_ics(calendar) do
    []
    |> start_calendar(calendar)
    |> scale(calendar)
    |> version(calendar)
    |> product_id(calendar)
    |> method(calendar)
    |> events(calendar)
    |> end_calendar(calendar)
  end

  defp start_calendar(acc, _calendar), do: acc ++ ["BEGIN:VCALENDAR\n"]
  defp end_calendar(acc, _calendar), do: acc ++ ["END:VCALENDAR\n"]

  defp scale(acc, %{scale: nil}), do: acc
  defp scale(acc, calendar), do: acc ++ ["CALSCALE:", calendar.scale, "\n"]

  defp method(acc, %{method: nil}), do: acc
  defp method(acc, calendar), do: acc ++ ["METHOD:", calendar.method, "\n"]

  defp version(acc, %{version: nil}), do: acc
  defp version(acc, calendar), do: acc ++ ["VERSION:", calendar.version, "\n"]

  defp product_id(acc, %{product_id: nil}), do: acc
  defp product_id(acc, calendar), do: acc ++ ["PRODID:", calendar.product_id, "\n"]

  defp events(acc, %{events: []}), do: acc

  defp events(acc, calendar) do
    acc ++ Enum.map(calendar.events, &ICalendar.Serialize.to_ics/1)
  end
end
