defmodule Crit.MultiStepCache do
  @moduledoc """
  Cache used user activities that occur in multiple steps.
  """
  import Pile.Interface

  def new_key, do: UUID.uuid4()

  def put_first(%{} = data) do 
    uuid = some(__MODULE__).new_key()
    :ok = ConCache.insert_new(Crit.Cache, uuid, data)
    uuid
  end

  def get(uuid_key) do
    ConCache.get(Crit.Cache, uuid_key)
  end

  def add(uuid_key, %{} = new_values) do
    ConCache.update(Crit.Cache, uuid_key, &({:ok, Map.merge(&1, new_values)}))
  end

  def add(uuid_key, key, value) do
    add(uuid_key, %{key => value})
  end

  def delete(uuid_key), do: ConCache.delete(Crit.Cache, uuid_key)
end
