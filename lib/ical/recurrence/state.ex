defmodule ICal.Recurrence.State do
  defstruct [
    :limit,
    :start_date,
    :end_date,
    :interval,
    :modifiers,
    :rule,
    exclude_dates: nil,
    other_recurrences: nil,
    fruitless_searches: 0
  ]

  @type recurrence :: Date.t() | DateTime.t() | NaiveDateTime.t()
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
          limit: :reached | non_neg_integer() | recurrence,
          start_date: recurrence,
          end_date: recurrence | nil,
          interval: Duration.duration(),
          modifiers: [{modifier_scope, modifier_mode}],
          rule: ICal.Recurrence.t(),
          exclude_dates: [recurrence],
          fruitless_searches: non_neg_integer()
        }
end
