# Derived from https://github.com/aliou/radch


defmodule Ecto.Timespan do
  @behaviour Ecto.Type

  # It's silly to duplicate Postgrex.Range.
  @enforce_keys [:first, :last, :lower_inclusive, :upper_inclusive]
  defstruct @enforce_keys

  defp normalize(%NaiveDateTime{} = value), do: value
  # An empty bound comes from the database as `:unbound`
  defp normalize(:unbound = value), do: value

  # Default date conversions are only accurate to microseconds. Using
  # them means a Timespan round-tripped through Postgres would come
  # back with extra digits of zeroes, which breaks tests.
  @zero_in_microseconds Time.from_erl!({0, 0, 0}, {0, 6})
  defp normalize(%Date{} = date) do
    {:ok, result} = NaiveDateTime.new(date, @zero_in_microseconds)
    result
  end

  def new(first, last, lower_inclusive, upper_inclusive) do 
    %__MODULE__{
      first: normalize(first),
      last: normalize(last),
      lower_inclusive: lower_inclusive,
      upper_inclusive: upper_inclusive
    }
  end

  # extends to negative infinity
  def infinite_down(last, :inclusive) do
    new(:unbound, last, false, true)
  end
  def infinite_down(last, :exclusive) do
    new(:unbound, last, false, false)
  end

  
  def infinite_up(first, :inclusive), do: new(first, :unbound, true, false)
  def infinite_up(first, :exclusive), do: new(first, :unbound, false, false)

  def customary(first, last), do: new(first, last, true, false)

  def plus(first, addition, :minute) do
    customary(first, NaiveDateTime.add(first, addition * 60, :second))
  end
  

  def for_instant(instant), do: new(instant, instant, true, true)


  

  @impl Ecto.Type
  def type, do: :tsrange

  @impl Ecto.Type
  def cast(%__MODULE__{} = range), do: {:ok, range}
  def cast(_), do: :error

  @impl Ecto.Type
  def load(%Postgrex.Range{} = range) do
    {:ok,
     new(range.lower, range.upper, range.lower_inclusive, range.upper_inclusive)
    }
  end
  def load(_), do: :error

  @impl Ecto.Type
  def dump(%__MODULE__{} = range) do
    {:ok,
     %Postgrex.Range{
      lower: range.first || :unbound,
      upper: range.last || :unbound,
      lower_inclusive: range.lower_inclusive,
      upper_inclusive: range.upper_inclusive
    }}
  end

  def dump(_), do: :error


  def dump!(x) do
    {:ok, result} = dump(x)
    result
  end


  defmacro overlaps(span1, span2) do
    quote do
      fragment("?::tsrange && ?::tsrange", unquote(span1), unquote(span2))
    end
  end

  defmacro contains(container, contained) do
    quote do
      fragment("?::tsrange @> ?::tsrange", unquote(container), unquote(contained))
    end
  end

end
