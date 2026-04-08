defmodule ICal.Event do
  @moduledoc """
  An iCalendar Event
  """

  @behaviour ICal.Alarm

  # credo:disable-for-next-line
  defstruct uid: nil,
            dtstamp: nil,
            created: nil,
            dtstart: nil,
            dtend: nil,
            modified: nil,
            recurrence_id: nil,
            exdates: [],
            rdates: [],
            rrule: nil,
            class: nil,
            description: nil,
            duration: nil,
            location: nil,
            status: nil,
            organizer: nil,
            sequence: nil,
            summary: nil,
            url: nil,
            geo: nil,
            priority: nil,
            transparency: nil,
            alarms: [],
            attachments: [],
            attendees: [],
            categories: [],
            comments: [],
            contacts: [],
            related_to: [],
            resources: [],
            request_status: [],
            custom_properties: %{}

  @type t :: %__MODULE__{
          uid: String.t() | nil,
          dtstamp: DateTime.t() | nil,
          created: DateTime.t() | nil,
          dtstart: Date.t() | DateTime.t() | nil,
          dtend: Date.t() | DateTime.t() | nil,
          modified: Date.t() | nil,
          recurrence_id: Date.t() | nil,
          exdates: [Date.t() | DateTime.t()],
          rdates: [Date.t() | DateTime.t() | ICal.period()],
          rrule: map() | nil,
          class: String.t() | nil,
          description: String.t() | nil,
          duration: ICal.Duration.t() | nil,
          location: String.t() | nil,
          organizer: String.t() | nil,
          sequence: String.t() | nil,
          status: :tentative | :confirmed | :cancelled | nil,
          summary: String.t() | nil,
          url: String.t() | nil,
          geo: ICal.geo() | nil,
          priority: integer | nil,
          transparency: :opaque | :transparent | nil,
          alarms: [ICal.Alarm.t()],
          attachments: [ICal.Attachment.t()],
          attendees: [String.t()],
          categories: [String.t()],
          comments: [String.t()],
          contacts: [ICal.Contact.t()],
          related_to: [String.t()],
          request_status: [ICal.RequestStatus.t()],
          resources: [String.t()],
          custom_properties: ICal.custom_properties()
        }

  @doc """
    Given an event with alarms, list the next alarm(s)
  """
  @impl ICal.Alarm
  def next_alarms(%__MODULE__{alarms: []}), do: []

  # when the event has no recurrences, but the event is in the future
  def next_alarms(
        %__MODULE__{
          dtstart: dtstart,
          dtend: dtend,
          rrule: recurrence,
          alarms: [%ICal.Alarm{trigger: %ICal.Alarm.Trigger{relative_to: alarm_relative_to}} | _]
        } = event
      )
      when is_nil(recurrence) do
    case alarm_relative_to do
      :end ->
        case in_future?(dtend) do
          false ->
            []

          true ->
            event.alarms
        end

      _ ->
        case in_future?(dtstart) do
          false ->
            []

          true ->
            event.alarms
        end
    end
  end

  # when the event has recurrences
  def next_alarms(%__MODULE__{rrule: recurrence} = event) when not is_nil(recurrence) do
    event
    |> ICal.Recurrence.stream()
    |> Stream.map(& &1.alarms)
    |> Enum.take(1)
  end

  # True when the event is in the future
  defp in_future?(date) do
    {:ok, date_zone_shifted} = DateTime.shift_zone(date, DateTime.utc_now().time_zone)

    case Timex.compare(DateTime.now!("Etc/UTC"), date_zone_shifted) do
      -1 -> true
      _ -> false
    end
  end
end
