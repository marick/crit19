defmodule Ecto.Datespan do
  use Ecto.Span, db_type: :daterange, type: Date

  defp convert_to_endpoint_type(%Date{} = date), do: date

  def strictly_before(%Date{} = date), do: infinite_down(date, :exclusive)
  def date_and_after(%Date{} = date), do: infinite_up(date, :inclusive)
end
