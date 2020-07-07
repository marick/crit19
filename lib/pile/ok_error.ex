defmodule Pile.OkError do
  def mark_ok(value), do: {:ok, value}
  def mark_error(value), do: {:error, value}
end
