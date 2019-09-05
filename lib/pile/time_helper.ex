
defmodule Pile.TimeHelper do

  @doc ~S"""
  If `maybe_iso` string is any string but one, it must be an ISO8601
  string that will be used to produce a `Date` representing the given day.

  If the string is "today", it produces a `Date` for today *in the
  given `location`*. That is, if a person asks for *today* a bit after
  midnight Wednesday in Manchester, England for a client in California,
  they'll get the `Date` for Tuesday.
  
  ## Examples
  
      iex> Pile.TimeHelper.location_day("2019-09-04", "America/Chicago")
      ~D[2019-09-04]
      
      iex> Pile.TimeHelper.location_day("today", "America/Chicago")
      ~D[2019-09-04]
  """
  def location_day(maybe_iso, location) do
    case maybe_iso do
      "today" ->
        {:ok, datetime} = DateTime.now(location)
        DateTime.to_date(datetime)
      _ -> 
        Date.from_iso8601!(maybe_iso)
    end
  end
end
