defmodule Pile.NamelistTest do
  use ExUnit.Case, async: true
  use Crit.TestConstants
  use Crit.Errors
  use Ecto.Schema
  import Crit.Assertions.Changeset
  alias Pile.Namelist
  alias Ecto.Changeset

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

  embedded_schema do
    field :names, :string
  end

  defp starting(value), do: Changeset.cast(%__MODULE__{}, %{names: value}, [:names])

  describe "validate" do
    test "success case" do
      starting("a, b")
      |> Namelist.validate(:names)
      |> assert_valid
    end
    
    test "an empty string is invalid" do
      starting("")
      |> Namelist.validate(:names)
      |> assert_invalid
      |> assert_error(names: @no_valid_names_message)
    end

    test "not fooled by a bunch of blanks" do
      starting("     \t   ")
      |> Namelist.validate(:names)
      |> assert_invalid
      |> assert_error(names: @no_valid_names_message)
    end
    
    test "not fooled by comma-separated nothingness" do
      starting("    , \t   ")
      |> Namelist.validate(:names)
      |> assert_invalid
      |> assert_error(names: @no_valid_names_message)
    end
    
    test "does not like duplicate names" do
      starting("a, b, a")
      |> Namelist.validate(:names)
      |> assert_invalid
      |> assert_error(names: @duplicate_name)
    end
    
  end
  
end
