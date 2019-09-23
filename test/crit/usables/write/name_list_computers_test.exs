defmodule Crit.Usables.Write.NameListComputersTest do
  use Ecto.Schema
  use Crit.DataCase
  alias Crit.Usables.Write.NameListComputers
  alias Ecto.Changeset

  embedded_schema do
    field :names, :string
    field :computed_names, {:array, :string}, virtual: true
  end
  
  def so_far(opts \\ []) do
    default = %{}
    Changeset.change(%__MODULE__{}, Enum.into(opts, default))
  end

  describe "splitting names" do
    test "computes names and handles whitespace" do
      changeset = 
        so_far(names: "  a, bb  , c   d ")
        |> NameListComputers.split_names
      
      assert changeset.changes.computed_names == ["a", "bb", "c   d"]
    end

    test "will reject sneaky way of getting an empty list" do
      errors = 
        so_far(names: " ,")
        |> NameListComputers.split_names
        |> errors_on
      
      assert errors.names == [NameListComputers.no_names_error_message]
    end
  end
end  
