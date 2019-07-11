defmodule Crit.OkError do

  @no_explanation "no explanation"

  def lift_error(:error,       message), do: {:error, message}
  def lift_error({:ok, value}, _______), do: {:ok, value}
  def lift_error(:error),                do: {:error, @no_explanation}
  def lift_error({:ok, value}),          do: {:ok, value}

  
  defp bad_use(bad_value), do: "bad use of `lift_nullable`: #{bad_value}"

  def lift_nullable(:error,   _message), do: raise bad_use(:error)
  def lift_nullable(:ok,      _message), do: raise bad_use(:ok)
  def lift_nullable({:ok, _}, ________), do: raise bad_use({:ok, "..."})
  def lift_nullable(nil,       message), do: {:error, message}
  def lift_nullable(value,    ________), do: {:ok, value}

  def lift_nullable(value), do: lift_nullable(value, @no_explanation)

  @irrelevant "irrelevant success value"

  def lift_oker(:error, message),        do: {:error, message}
  def lift_oker(:ok,    ________),       do: {:ok, @irrelevant}
  def lift_oker(value,  ________),       do: raise bad_use(value)

  def lift_oker(value), do: lift_oker(value, @no_explanation)
end
