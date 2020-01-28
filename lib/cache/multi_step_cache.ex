defmodule Crit.MultiStepCache do
  @moduledoc """
  Cache used user activities that occur in multiple steps.
  """
  import Pile.Interface
  

  def new_key, do: UUID.uuid4()

  def put_first(data) do 
    uuid = some(__MODULE__).new_key()
    :ok = ConCache.insert_new(Crit.Cache, uuid, Map.from_struct(data))
    uuid
  end

  def get(key) do
    ConCache.get(Crit.Cache, key)
  end
  
end
