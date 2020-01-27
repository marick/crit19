defmodule Ecto.Timespan do
  use Ecto.Span, outer_type: :tsrange,
                 inner_type: {:timestamp, NaiveDateTime}
  alias Pile.TimeHelper

  defp convert_to_endpoint_type(%NaiveDateTime{} = endpoint), do: endpoint

  # Postgres uses microsecond precision, and NaiveDateTimes use
  # millisecond by default. Forcing microsecond precision makes a
  # number of tests easier (but a few harder), and it's irrelevant to
  # the domain if some Timespans have six digits of precision and some
  # have three.
  
  defp convert_to_endpoint_type(%Date{} = date) do
    TimeHelper.millisecond_precision(date)
  end

  def plus(first, addition, :minute) do
    customary(first, NaiveDateTime.add(first, addition * 60, :second))
  end

  def from_date_time_and_duration(%Date{} = date, %Time{} = time, minutes) do
    {:ok, start} = NaiveDateTime.new(date, time)
    start
    |> TimeHelper.millisecond_precision
    |> plus(minutes, :minute)
  end
end
