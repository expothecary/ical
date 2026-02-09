defmodule ICalendar.Deserialize do
  @moduledoc false
  def from_ics(ics) when is_binary(ics) do
    ICalendar.Deserialize.Calendar.one(ics)
  end
end
