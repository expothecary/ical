defmodule ICal.Attendee do
  @moduledoc """
  An ICal attendee. While the name is required, other fields are optional.

  For details on the meaning of the fields, see https://datatracker.ietf.org/doc/html/rfc5545#section-3.8.4.1
  """
  @enforce_keys [:name]
  defstruct [
    :name,
    language: nil,
    type: nil,
    membership: [],
    role: nil,
    status: nil,
    rsvp: false,
    delegated_to: [],
    delegated_from: [],
    sent_by: nil,
    cname: nil,
    dir: nil
  ]

  @type t :: %__MODULE__{
          name: String.t(),
          language: String.t() | nil,
          type: String.t() | nil,
          membership: [String.t()],
          role: String.t() | nil,
          status: String.t() | nil,
          rsvp: boolean,
          delegated_to: [String.t()],
          delegated_from: [String.t()],
          sent_by: String.t() | nil,
          cname: String.t() | nil,
          dir: String.t() | nil
        }
end
