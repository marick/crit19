defmodule Ecto.Timespan do
  use Ecto.Span, db_type: :tsrange

  @behaviour Ecto.Type


  defp convert_to_endpoint_type(%NaiveDateTime{} = endpoint), do: endpoint

  # Default date conversions are only accurate to microseconds. Using
  # them means a Timespan round-tripped through Postgres would come
  # back with extra digits of zeroes, which breaks tests.
  @zero_in_microseconds Time.from_erl!({0, 0, 0}, {0, 6})
  defp convert_to_endpoint_type(%Date{} = endpoint) do
    {:ok, result} = NaiveDateTime.new(endpoint, @zero_in_microseconds)
    result
  end

  def plus(first, addition, :minute) do
    customary(first, NaiveDateTime.add(first, addition * 60, :second))
  end

  def from_date_time_and_duration(%Date{} = date, %Time{} = time, minutes) do
    {:ok, start} = NaiveDateTime.new(date, time)
    plus(start, minutes, :minute)
  end

end
