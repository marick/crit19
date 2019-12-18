defmodule Ecto.Datespan do
  use Ecto.Span, db_type: :daterange, type: Date

  defp convert_to_endpoint_type(%Date{} = date), do: date

  def convert_to_customary(datespan, last),
    do: customary(datespan.first, last)


  def is_customary?(datespan), 
    do: datespan.first != :unbound && datespan.last != :unbound
end
