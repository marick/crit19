defmodule Crit.State.UserTask do
  @moduledoc """
  Cache used user activities that occur in multiple steps.
  """
  import Pile.Interface
  alias Ecto.Changeset

  def new_id, do: UUID.uuid4()

  def start(module) do
    task_id = some(__MODULE__).new_id()
    starting_struct = struct(module, task_id: task_id)
    :ok = ConCache.insert_new(Crit.Cache, task_id, starting_struct)
    starting_struct
  end

  def start(module, initial, opts \\ []) do
    %{task_id: key} = start(module)
    store_by_key(key, initial, opts)
  end

  def store(%{task_id: key} = new_values, opts \\ []) do
    store_by_key(key, new_values, opts)
  end

  def get(task_id) do
    ConCache.get(Crit.Cache, task_id)
  end

  def delete(task_id), do: ConCache.delete(Crit.Cache, task_id)

  def validate_task_id(changeset) do
    # It is fine for the fetch to blow up because a missing task id
    # is either a program error or someone tampering with the form params.
    task_id = Changeset.fetch_change!(changeset, :task_id)
    case get(task_id) do
      nil -> Changeset.add_error(changeset, :task_id, "has expired")
      _ -> changeset
    end
  end

  def expiry_message, do: "This task has expired; you will have to start again."
  
  def pour_into_struct(params, struct_module) do
    changeset = apply(struct_module, :changeset, [params])
    if Enum.member?(Keyword.keys(changeset.errors), :task_id) do
      {:task_expiry, expiry_message()}
    else
      Changeset.apply_action(changeset, :insert)
    end
  end

  # ----------------------------------------------------------------------------
  defp store_by_key(key, %{} = new_values, opts) do
    total = Enum.into(opts, Map.from_struct(new_values) |> Map.delete(:task_id))

    updater = fn old ->
      {:ok, Map.merge(old, total)}
    end
    :ok = ConCache.update(Crit.Cache, key, updater)
    get(key)
  end
end
