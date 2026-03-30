defmodule Ical.Alarm.AlarmBehaviour do
    @callback next_alarms(event :: Ical.Event.t()) :: Enumerable.t(Ical.Alarm.t())
end
