defmodule Crit.MultiStepCacheTest do 
  use ExUnit.Case, async: true
  alias Crit.MultiStepCache, as: Cache

  defstruct name: nil, id: nil, species: nil

  # There are some dubious choices here that will probably change

  test "a big glob" do
    key = Cache.put_first(%__MODULE__{name: "fred", id: 3})
    assert %{name: "fred", id: 3} = Cache.get(key)
    
    assert :ok == Cache.add(key, %{name: "new", species: 2})
    assert %{name: "new", id: 3, species: 2} = Cache.get(key)

    assert :ok == Cache.add(key, :id, 4)
    assert %{name: "new", id: 4, species: 2} = Cache.get(key)
  end


  test "deletion" do
    key = Cache.put_first(%__MODULE__{name: "fred", id: 3})
    Cache.delete(key)
    assert nil = Cache.get(key)
  end
end

