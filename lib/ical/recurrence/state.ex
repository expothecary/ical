defmodule ICal.Recurrence.State do
  @moduledoc false

  defstruct [
    :limit,
    :earliest_date,
    :start_date,
    :end_date,
    :interval,
    :modifiers,
    :rule,
    exclude_dates: nil,
    other_recurrences: nil,
    fruitless_searches: 0,
    error: :none
  ]

  @type recurrence_date :: Date.t() | DateTime.t()
  @type error_reason :: :none | :search_exhaustion | :no_defined_limit
  @type modifier_scope ::
          :by_month
          | :by_week_number
          | :by_year_day
          | :by_month_day
          | :by_day
          | :by_hour
          | :by_minute
          | :by_second
          | :by_set_position
  @type modifier_mode :: :limit | :expand | :expand_week | :expand_month | :expand_year

  @type t :: %__MODULE__{
          earliest_date: recurrence_date(),
          end_date: recurrence_date() | nil,
          error: error_reason(),
          exclude_dates: [recurrence_date()],
          fruitless_searches: non_neg_integer(),
          interval: {:date | :time, Duration.duration()},
          limit: :reached | non_neg_integer() | recurrence_date(),
          modifiers: [{modifier_scope, modifier_mode}],
          rule: ICal.Recurrence.t(),
          start_date: recurrence_date()
        }
end
