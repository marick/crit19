defmodule Crit.Servers.UserTask do
  @moduledoc """
  Cache used user activities that occur in multiple steps.
  """
  import Pile.Aspect, only: [some: 1]
  alias Ecto.Changeset

  def new_id, do: UUID.uuid4()

  def start(module) do
    task_id = some(__MODULE__).new_id()
    starting_struct = struct(module, task_id: task_id)
    :ok = ConCache.insert_new(Crit.Cache, task_id, starting_struct)
    starting_struct
  end

  def start(module, initial_values) do
    struct = start(module)
    store_by_task_id(struct.task_id, struct, initial_values)
  end

  def remember_relevant(%{task_id: task_id} = new_values, extras \\ []) do
    store_by_task_id(task_id, new_values, extras)
  end

  def put(task_id, key, value) do
    updater = fn old ->
      {:ok, Map.put(old, key, value)}
    end
    :ok = ConCache.update(Crit.Cache, task_id, updater)
    get(task_id)
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
      task_id = Changeset.fetch_change!(changeset, :task_id)
      changeset
      |> Changeset.apply_action(:insert)
      |> Tuple.append(task_id)
    end
  end

  # ----------------------------------------------------------------------------
  defp store_by_task_id(task_id, %{} = new_values, extras) when is_struct(new_values) do
    total = Enum.into(
      extras,
      Map.from_struct(new_values) |> Map.delete(:task_id))

    updater = fn old ->
      {:ok, Map.merge(old, total)}
    end
    :ok = ConCache.update(Crit.Cache, task_id, updater)
    get(task_id)
  end
end
