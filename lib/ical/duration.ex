defmodule ICal.Duration do
  @moduledoc """
  A struct representing an ICal duration, representing the numbers days, weeks, and/or a measure time over which something occurs or lasts.

  See: https://datatracker.ietf.org/doc/html/rfc5545#section-3.8.2.5
  """

  defstruct positive: true,
            time: {0, 0, 0},
            days: 0,
            weeks: 0

  @type duration_time ::
          {hours :: non_neg_integer(), minutes :: non_neg_integer(), seconds :: non_neg_integer()}

  @type t :: %__MODULE__{
          positive: bool,
          time: duration_time,
          days: non_neg_integer(),
          weeks: non_neg_integer()
        }
end
