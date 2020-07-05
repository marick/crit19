defmodule ListXTest do
  use ExUnit.Case, async: true

  describe "from_namelist" do
    test "typical" do
      actual = ListX.from_namelist("name, name2, name3")
      assert ["name", "name2", "name3"] == actual
    end
      
    test "blanks are trimmed" do
      assert ListX.from_namelist("name ") == ["name"]
      assert ListX.from_namelist("\tname ") == ["name"]
    end

    test "empty string is ok" do
      assert ListX.from_namelist("    ") == []
    end

    test "allow extra commas" do
      assert ListX.from_namelist("  ,  , b") == ["b"]
    end
  end
end
