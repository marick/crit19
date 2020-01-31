defmodule Crit.MultiStepCacheTest do 
  use ExUnit.Case, async: true
  alias Crit.MultiStepCache, as: Cache

  defstruct name: nil, id: nil, species: nil

  # There are some dubious choices here that will probably change

  test "a big glob" do
    first = %__MODULE__{name: "fred", id: 3}
    {key, ^first} = Cache.put_first(first)
    assert %{name: "fred", id: 3} = Cache.get(key)

    second = %__MODULE__{name: "new", id: 3, species: 2}
    assert second == Cache.put_more(%{name: "new", species: 2}, key)
    assert second == Cache.get(key)

    third = %__MODULE__{name: "new", id: 4, species: 2}
    assert third == Cache.put_more(:id, 4, key)
    assert third == Cache.get(key)
  end


  test "deletion" do
    key = Cache.put_first(%__MODULE__{name: "fred", id: 3})
    Cache.delete(key)
    assert nil == Cache.get(key)
  end
end

