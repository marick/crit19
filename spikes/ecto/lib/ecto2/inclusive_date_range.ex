defmodule Ecto2.InclusiveDateRange do

  @behaviour Ecto.Type

  @enforce_keys [:first, :last]
  defstruct @enforce_keys

  # TODO: Use timex intervals
  @type t :: %__MODULE__{
    first: Date.t(),
    last: Date.t()
  }

  def new(first, last),
    do: %__MODULE__{first: first, last: last}

  # extends to negative infinity
  def ending_at(last), do: new(nil, last) 
  def starting_at(first), do: new(first, nil)


  def type, do: :daterange

  def cast(%__MODULE__{} = range), do: {:ok, range}
  def cast(_), do: :error

  def load(%Postgrex.Range{} = range) do
    {:ok, new(range.lower, range.upper) }
  end
  def load(_), do: :error

  def dump(%_{} = range) do
    {:ok,
     %Postgrex.Range{
      lower: range.first,
      upper: range.last,
      lower_inclusive: true,
      upper_inclusive: true
    }}
  end

  def dump(_), do: :error

end
