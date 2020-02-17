defmodule Crit.State.UserTaskTest do 
  use ExUnit.Case, async: true
  alias Crit.State.UserTask

  defstruct name: nil, id: nil, species: nil

  # There are some dubious choices here that will probably change

  test "a big glob" do
    first = %__MODULE__{name: "fred", id: 3}
    {key, ^first} = UserTask.cast_first(first)
    assert %{name: "fred", id: 3} = UserTask.get(key)

    second = %__MODULE__{name: "new", id: 3, species: 2}
    assert second == UserTask.cast_more(%{name: "new", species: 2}, key)
    assert second == UserTask.get(key)

    third = %__MODULE__{name: "new", id: 4, species: 2}
    assert third == UserTask.cast_more(:id, 4, key)
    assert third == UserTask.get(key)
  end


  test "deletion" do
    key = UserTask.cast_first(%__MODULE__{name: "fred", id: 3})
    UserTask.delete(key)
    assert nil == UserTask.get(key)
  end
end

