defmodule Ecto.Datespan do
  use Ecto.Span, db_type: :daterange, type: Date

  defp convert_to_endpoint_type(%Date{} = date), do: date

  def start_string(span), do: span.first |> Date.to_iso8601
  def end_string(span), do: span.last |> Date.to_iso8601
end
