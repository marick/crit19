# This is all wrong. Probably better to have it be an isolated
# module that knows how to get the institution timezone.
defmodule Pile.TimeHelper do

  @doc ~S"""
  Produces a `Date` for today *in the given `location`*. That is, if a
  person asks for *today* a bit after midnight Wednesday in
  Manchester, England for a client in California, they'll get the
  `Date` for Tuesday.
  """
  def today_date(location) do
    {:ok, datetime} = DateTime.now(location)
    DateTime.to_date(datetime)
  end

  def stub_today_date(location, [to_return: retval]),
    do: fn ^location -> retval end

  def institution_timezone(_institution) do
    "America/Chicago"
  end

  
end
