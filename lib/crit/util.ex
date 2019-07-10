defmodule Crit.Util do

  # Edging toward an error monad
  
  def to_Error(nil, on_error), do: {:error, on_error}
  def to_Error(value, _), do: {:ok, value}
  def to_Error(nil), do: to_Error(nil, "no explanation")
end
