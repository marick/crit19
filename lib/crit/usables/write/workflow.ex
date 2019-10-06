defmodule Crit.Usables.Write.Workflow do

  def run(attrs, institution, steps) do
    run_steps(%{attrs: attrs, institution: institution}, steps)
  end

  def run_steps(state, []),
    do: {:ok, state}
  
  def run_steps(state, [next | rest]) do
    case next.(state) do
      {:ok, state} ->
        run_steps(state, rest)
      error ->
        error
    end
  end


  def validation_step(%{attrs: attrs} = state, validator, result_key) do 
    changeset = validator.(attrs)
    if changeset.valid? do
      {:ok, Map.put(state, result_key, changeset)}
    else
      {:error, changeset}
    end
  end


  # Handle return value from an Sql.transaction.
  
  def on_ok({:ok, tx_result}, [extract: key]) do
    {:ok, tx_result[key]}
  end
  def on_ok(fall_through, _), do: fall_through

  def on_failed_step({:error, step, failing_changeset, _so_far}, handler) do
    handler.(step, failing_changeset)
  end
  def on_failed_step(fall_through, _), do: fall_through
  


end  
