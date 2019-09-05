defmodule Ecto.Datespan do
  use Ecto.Span, db_type: :daterange
  @behaviour Ecto.Type

  defp convert_to_endpoint_type(%Date{} = date), do: date
end
