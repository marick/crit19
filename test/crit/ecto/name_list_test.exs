defmodule Crit.Ecto.NameListTest do
  use ExUnit.Case, async: true

  alias Crit.Ecto.NameList

  test "casting" do
    assert NameList.cast("name, name2, name3") ==
      {:ok, ["name", "name2", "name3"]}

    assert NameList.cast("name ") == {:ok, ["name"]}

    assert NameList.cast(1) == :error
  end

  test "casting removes blank strings" do
    # It's unlikely that producing a message about a typo and stopping
    # creation of animals would be useful.
    assert NameList.cast(" ") == {:ok, []}
    assert NameList.cast("a,, b ") == {:ok, ["a", "b"]}
  end


  test "casting removes duplicates strings" do
    # It's unlikely that producing a message about a typo and stopping
    # creation of animals would be useful.
    assert NameList.cast("a , b,a, c, a") == {:ok, ["a", "b", "c"]}
  end


  test "loading and dumping do not work - this is for virtual fields" do
    untrimmed = "stuff"
    assert NameList.load(untrimmed) == :error
    assert NameList.dump(untrimmed) == :error
  end
end
