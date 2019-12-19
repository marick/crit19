defmodule Ecto.Datespan do
  use Ecto.Span, db_type: :daterange, type: Date
  use Crit.Global.Constants

  defp convert_to_endpoint_type(%Date{} = date), do: date

  def put_last(datespan, last),
    do: customary(datespan.first, last)

  def is_customary?(datespan), 
    do: datespan.first != :unbound && datespan.last != :unbound &&
          datespan.lower_inclusive == true && datespan.upper_inclusive == false 

  def inclusive_up(date), do: infinite_up(date, :inclusive)

  # Note that this blows up for an infinite-down span.
  def first_to_string(%__MODULE__{first: %Date{} = first}),
    do: Date.to_iso8601(first)

  def last_to_string(%__MODULE__{last: %Date{} = last}),
    do: Date.to_iso8601(last)
  def last_to_string(%__MODULE__{last: :unbound}),
      do: @never

end
