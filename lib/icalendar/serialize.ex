defprotocol ICalendar.Serialize do
  @doc """
  Serialize data to iCalendar format.

  Supported options for serializing a calendar:

    * `vendor` a string containing the vendor's name. Will produce
      `PRODID:-//ICalendar//My Name//EN`.
    * `headers` a keyword list containing the headers to 
      be placed in the  calendar header: `[{"Method", "Request"}]`
  """
  def to_ics(data, options \\ [])
end

alias ICalendar.Serialize

defimpl Serialize, for: List do
  def to_ics(collection, _options \\ []) do
    Enum.map_join(collection, "\n", &Serialize.to_ics/1)
  end
end
