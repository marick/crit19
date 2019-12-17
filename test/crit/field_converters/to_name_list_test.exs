defmodule Crit.FieldConverters.ToNameListTest do
  use Ecto.Schema
  use Crit.DataCase
  alias Crit.FieldConverters.ToNameList
  alias Ecto.Changeset

  # This works on a schema with two fields with this structure:
  
  embedded_schema do
    field :from_field, :string
    field :to_field, {:array, :string}, virtual: true
  end

  def split_names(changeset),
    do: ToNameList.split_names(changeset, from: :from_field, to: :to_field)
  
  def changeset_containing(opts) do
    Changeset.change(%__MODULE__{}, opts)
  end

  describe "splitting names" do
    test "computes names and handles whitespace" do
      actual =
        changeset_containing(from_field: "  a, bb  , c   d ")
        |> split_names
      
      assert actual.changes.to_field == ["a", "bb", "c   d"]
    end

    test "will reject a sneaky way of getting an empty list" do
      errors =
        changeset_containing(from_field: " ,")
        |> split_names
        |> errors_on

      assert errors.from_field == [@no_valid_names_message]
    end
  end
end  
