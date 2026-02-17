defmodule ICal.Deserialize.Attendee do
  @moduledoc false

  alias ICal.Deserialize

  def one(data) do
    {data, params} = Deserialize.params(data)
    {data, value} = Deserialize.rest_of_line(data)

    attendee = %ICal.Attendee{
      name: value,
      language: Map.get(params, "LANGUAGE"),
      type: Map.get(params, "CUTYPE"),
      membership: List.wrap(Map.get(params, "MEMBER")),
      role: Map.get(params, "ROLE"),
      status: Map.get(params, "PARTSTAT"),
      rsvp: rsvp(params),
      delegated_to: List.wrap(Map.get(params, "DELEGATED-TO")),
      delegated_from: List.wrap(Map.get(params, "DELEGATED-FROM")),
      sent_by: Map.get(params, "SENT-BY"),
      cname: Map.get(params, "CN"),
      dir: Map.get(params, "DIR")
    }

    {data, attendee}
  end

  defp rsvp(%{"RSVP" => "TRUE"}), do: true
  defp rsvp(_), do: false
end
