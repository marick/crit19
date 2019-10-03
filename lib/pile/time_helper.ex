# This is all wrong. Probably better to have it be an isolated
# module that knows how to get the institution timezone.
defmodule Pile.TimeHelper do

  @doc ~S"""
  Produces a `Date` for today *in the given `timezone`*. That is, if a
  person asks for *today* a bit after midnight Wednesday in
  Manchester, England for a client in California, they'll get the
  `Date` for Tuesday.
  """
  def today_date(timezone) do
    {:ok, datetime} = DateTime.now(timezone)
    DateTime.to_date(datetime)
  end

  def stub_today_date(timezone, [to_return: retval]),
    do: fn ^timezone -> retval end

  # Default date conversions are only accurate to microseconds. Using
  # them means that values round-tripped through Postgres would come
  # back with extra digits of zeroes, which breaks tests.
  
  def millisecond_precision(%NaiveDateTime{} = time) do
    as_erl = NaiveDateTime.to_erl(time)
    NaiveDateTime.from_erl!(as_erl, {0, 6})
  end

  def millisecond_precision(%Date{} = date) do
    zero_in_milliseconds = Time.from_erl!({0, 0, 0}, {0, 6})
    {:ok, result} = NaiveDateTime.new(date, zero_in_milliseconds)
    result
  end
end
