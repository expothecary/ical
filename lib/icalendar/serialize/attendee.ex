defmodule ICalendar.Serialize.Attendee do
  alias ICalendar.Serialize

  def to_ics(%ICalendar.Attendee{} = attendee) do
    ["ATTENDEE"]
    |> serialize_language(attendee)
    |> serialize_type(attendee)
    |> serialize_membership(attendee)
    |> serialize_role(attendee)
    |> serialize_status(attendee)
    |> serialize_rsvp(attendee)
    |> serialize_delegated_to(attendee)
    |> serialize_delegated_from(attendee)
    |> serialize_sent_by(attendee)
    |> serialize_cname(attendee)
    |> serialize_dir(attendee)
    |> serialize_name(attendee)
  end

  defp serialize_language(acc, %{language: nil}), do: acc
  defp serialize_language(acc, %{language: lang}), do: acc ++ [";LANGUAGE=", lang]

  defp serialize_type(acc, %{type: nil}), do: acc
  defp serialize_type(acc, %{type: type}), do: acc ++ [";CUTYPE=", type]

  defp serialize_membership(acc, %{membership: []}), do: acc

  defp serialize_membership(acc, %{membership: memberships}) do
    acc ++ [";MEMBER=", Serialize.to_quoted_comma_list(memberships)]
  end

  defp serialize_role(acc, %{role: nil}), do: acc
  defp serialize_role(acc, %{role: role}), do: acc ++ [";ROLE=", role]

  defp serialize_status(acc, %{status: nil}), do: acc
  defp serialize_status(acc, %{status: status}), do: acc ++ [";PARTSTAT=", status]

  defp serialize_rsvp(acc, %{rsvp: true}), do: acc ++ [";RSVP=TRUE"]
  defp serialize_rsvp(acc, _), do: acc

  defp serialize_delegated_to(acc, %{delegated_to: []}), do: acc

  defp serialize_delegated_to(acc, %{delegated_to: to}) do
    acc ++ [";DELEGATED-TO=", Serialize.to_quoted_comma_list(to)]
  end

  defp serialize_delegated_from(acc, %{delegated_from: []}), do: acc

  defp serialize_delegated_from(acc, %{delegated_from: from}) do
    acc ++ [";DELEGATED-FROM=", Serialize.to_quoted_comma_list(from)]
  end

  defp serialize_sent_by(acc, %{sent_by: nil}), do: acc

  defp serialize_sent_by(acc, %{sent_by: sent_by}) do
    acc ++ [";SENT-BY=\"", Serialize.escaped_quotes(sent_by), ?"]
  end

  defp serialize_cname(acc, %{cname: nil}), do: acc

  defp serialize_cname(acc, %{cname: cname}) do
    acc ++ [";CN=\"", Serialize.escaped_quotes(cname), ?"]
  end

  defp serialize_dir(acc, %{dir: nil}), do: acc

  defp serialize_dir(acc, %{dir: dir}) do
    acc ++ [";DIR=\"", Serialize.escaped_quotes(dir), ?"]
  end

  defp serialize_name(acc, %{name: name}), do: acc ++ [?:, name, ?\n]
end
