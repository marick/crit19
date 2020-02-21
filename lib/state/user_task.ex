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

  def pour_into_struct(params, struct_module) do
    apply(struct_module, :changeset, [params])
    |> Changeset.apply_action(:insert)
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
