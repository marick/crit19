# Derived from https://github.com/aliou/radch


defmodule Ecto2.Timespan do
  @behaviour Ecto.Type
  import Ecto.Query

  # It's silly to duplicate Postgrex.Range.
  @enforce_keys [:first, :last, :lower_inclusive, :upper_inclusive]
  defstruct @enforce_keys

  defp normalize(%NaiveDateTime{} = value), do: value
  defp normalize(nil = value), do: value
  defp normalize(%Date{} = date) do
    {:ok, result} = NaiveDateTime.new(date, ~T[00:00:00.000])
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
    new(nil, last, false, true)
  end
  def infinite_down(last, :exclusive) do
    new(nil, last, false, false)
  end

  
  def infinite_up(first, :inclusive), do: new(first, nil, true, false)
  def infinite_up(first, :exclusive), do: new(first, nil, false, false)

  def customary(first, last), do: new(first, last, true, false)

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
      lower: range.first,
      upper: range.last,
      lower_inclusive: range.lower_inclusive,
      upper_inclusive: range.upper_inclusive
    }}
  end

  def dump(_), do: :error


  defmacro overlaps(span1, span2) do
    quote do 
      fragment("? && ?::tsrange", unquote(span1), unquote(span2))
    end
  end

end
