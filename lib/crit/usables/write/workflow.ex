defmodule Crit.Usables.Write.Workflow do
  alias Crit.Sql
  alias Crit.Usables.Write
  alias Crit.Ecto.BulkInsert
  alias Crit.Global
  alias Ecto.Changeset

  def run(attrs, institution, steps, result_key) do
    result = run_steps(%{attrs: attrs, institution: institution}, steps)
    case result do
      {:ok, state} ->
        {:ok, Map.get(state, result_key)}
      error ->
        error
    end
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

end  
