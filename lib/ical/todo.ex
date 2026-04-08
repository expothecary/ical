defmodule ICal.Todo do
  @moduledoc """
  An iCalendar TODO component.
  """
  @behaviour ICal.Alarm

  # credo:disable-for-next-line
  defstruct [
    :uid,
    :dtstamp,
    created: nil,
    completed: nil,
    dtstart: nil,
    modified: nil,
    recurrance_id: nil,
    exdates: [],
    rdates: [],
    rrule: nil,
    class: nil,
    description: nil,
    duration: nil,
    location: nil,
    status: nil,
    organizer: nil,
    sequence: 0,
    summary: nil,
    url: nil,
    geo: nil,
    priority: 0,
    percent_completed: 0,
    due: nil,
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
  ]

  @type maybe :: %__MODULE__{}

  @type t :: %__MODULE__{
          uid: String.t(),
          dtstamp: DateTime.t(),
          created: nil | DateTime.t(),
          completed: nil | DateTime.t(),
          modified: nil | DateTime.t(),
          recurrance_id: nil | DateTime.t() | Date.t(),
          exdates: [Date.t() | DateTime.t()],
          rdates: [Date.t() | DateTime.t() | ICal.period()],
          class: nil | String.t(),
          description: nil | String.t(),
          dtstart: nil | DateTime.t() | Date.t(),
          geo: nil | ICal.geo(),
          location: nil | String.t(),
          organizer: nil | String.t(),
          percent_completed: non_neg_integer,
          priority: non_neg_integer,
          sequence: non_neg_integer,
          status: :need_action | :completed | :in_process | :cancelled | nil,
          summary: nil | String.t(),
          url: nil | String.t(),
          rrule: nil | ICal.Recurrence.t(),
          due: nil | DateTime.t() | Date.t(),
          duration: nil | ICal.Duration.t(),
          alarms: [ICal.Alarm.t()],
          attachments: [ICal.Attachment.t()],
          attendees: [ICal.Attendee.t()],
          categories: [String.t()],
          comments: [String.t()],
          contacts: [ICal.Contact.t()],
          request_status: [String.t()],
          related_to: [String.t()],
          resources: [String.t()],
          custom_properties: ICal.custom_properties()
        }

  @impl ICal.Alarm
  @spec next_alarms(ICal.Todo.t()) :: Enumerable.t(ICal.Alarm.t())
  def next_alarms(%__MODULE__{alarms: []}), do: []

  # when the todo has no recurrences, but the todo is in the future
  def next_alarms(%__MODULE__{dtstart: dtstart, rrule: recurrence} = todo)
      when is_nil(recurrence) do
    case in_future?(dtstart) do
      false ->
        []

      true ->
        todo.alarms
    end
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
