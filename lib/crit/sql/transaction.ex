defmodule Crit.Sql.Transaction do
  use Crit.Errors
  use ExContract

  
  def simplify_result({:ok, tx_result}, :return_inserted_values),
    do: {:ok, Map.values(tx_result) |> EnumX.sort_by_id}

  def simplify_result({:ok, tx_result}, [extract: result_name]),
    do: {:ok, tx_result[result_name]}

  def simplify_result({:error, _, _, _} = tx_result, _) do
    {_, {_, index}, failing_changeset, _} = tx_result
    {:error, index, failing_changeset}
  end
end  
