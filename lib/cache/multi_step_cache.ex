defmodule Crit.MultiStepCache do
  @moduledoc """
  Cache used user activities that occur in multiple steps.
  """
  import Pile.Interface

  def new_key, do: UUID.uuid4()


  # The `cast` terminology is because this works something like a Changeset
  # `cast` function: it ignores unmentioned fields (in this case fields that
  # are not part of the struct that the key is first initialized as.
  #
  # Also, like `cast`, it produces a result that may be suitable for chaining,
  # rather than just `:ok`.

  def cast_first(data) when is_struct(data) do 
    uuid = some(__MODULE__).new_key()
    :ok = ConCache.insert_new(Crit.Cache, uuid, data)
    {uuid, data}
  end

  def get(uuid_key) do
    ConCache.get(Crit.Cache, uuid_key)
  end

  def cast_more(%{} = new_values, uuid_key) do
    :ok = ConCache.update(Crit.Cache, uuid_key, &({:ok, Map.merge(&1, new_values)}))
    get(uuid_key)
  end

  def cast_more(key, value, uuid_key) do
    cast_more(%{key => value}, uuid_key)
  end

  def delete(uuid_key), do: ConCache.delete(Crit.Cache, uuid_key)
end
