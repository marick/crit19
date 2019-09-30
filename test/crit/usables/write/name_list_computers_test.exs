defmodule Crit.Usables.Write.NameListComputersTest do
  use Ecto.Schema
  use Crit.DataCase
  alias Crit.Usables.Write.NameListComputers
  alias Ecto.Changeset

  # This is the subset of the Read.Animal schema that `NameListComputers` operates on.
  embedded_schema do
    field :names, :string
    field :computed_names, {:array, :string}, virtual: true
  end
  
  def make_changeset_with_names(opts \\ []) do
    default = %{}
    Changeset.change(%__MODULE__{}, Enum.into(opts, default))
  end

  describe "splitting names" do
    test "computes names and handles whitespace" do
      actual =
        [names: "  a, bb  , c   d "]
        |> make_changeset_with_names
        |> NameListComputers.split_names
      
      assert actual.changes.computed_names == ["a", "bb", "c   d"]
    end

    test "will reject a sneaky way of getting an empty list" do
      errors =
        [names: " ,"]
        |> make_changeset_with_names
        |> NameListComputers.split_names
        |> errors_on
      
      assert errors.names == [NameListComputers.no_names_error_message]
    end
  end
end  
