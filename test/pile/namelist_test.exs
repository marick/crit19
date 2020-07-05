defmodule Pile.NamelistTest do
  use ExUnit.Case, async: true
  alias Pile.Namelist

  describe "to_list" do
    test "typical" do
      actual = Namelist.to_list("name, name2, name3")
      assert ["name", "name2", "name3"] == actual
    end
      
    test "blanks are trimmed" do
      assert Namelist.to_list("name ") == ["name"]
      assert Namelist.to_list("\tname ") == ["name"]
    end

    test "empty string is ok" do
      assert Namelist.to_list("    ") == []
    end

    test "allow extra commas" do
      assert Namelist.to_list("  ,  , b") == ["b"]
    end
  end
end
