defmodule ICalendar.Deserialize do
  def from_ics(ics) when is_binary(ics) do
    ICalendar.Deserialize.Calendar.one(ics)
  end
end
