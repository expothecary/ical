defprotocol ICalendar.Serialize do
  @doc """
  Serialize data to iCalendar format.
  """
  def to_ics(data)
end

alias ICalendar.Serialize

defimpl Serialize, for: List do
  def to_ics(collection) do
    Enum.map(collection, &Serialize.to_ics/1)
  end
end
