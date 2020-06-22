defmodule Ecto.ChangesetXTest do
  use ExUnit.Case, async: true
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.ChangesetX

  embedded_schema do
    field :field, :integer
  end

  describe "fetching the original (underlying) value" do
    setup do
      [changeset: change(%__MODULE__{field: 1})]
    end

    test "fetches the value", %{changeset: changeset} do
      assert ChangesetX.fetch_original!(changeset, :field) == 1
    end

    test "fetches a change", %{changeset: changeset} do
      changed = put_change(changeset, :field, 3)
      assert ChangesetX.fetch_original!(changed, :field) == 1
    end

    test "error when value does not exist", %{changeset: changeset} do
      msg =
        "key :missing not found in: %Ecto.ChangesetXTest{field: 1, id: nil}"
      assert_raise(KeyError, msg, fn -> 
        ChangesetX.fetch_original!(changeset, :missing)
      end)
    end

    test "all_valid?" do
      valid = %{valid?: true}
      invalid = %{valid?: false}

      assert ChangesetX.all_valid?(valid,   [])
      refute ChangesetX.all_valid?(invalid, [])

      assert ChangesetX.all_valid?(valid,   [valid,   valid])
      refute ChangesetX.all_valid?(invalid, [valid,   valid])
      refute ChangesetX.all_valid?(valid,   [invalid, valid])
      refute ChangesetX.all_valid?(valid,   [valid,   invalid])
    end
  end

  defmodule Deletable do
    use Ecto.Schema
    @primary_key false
    embedded_schema do
      field :id, :id
      field :delete, :boolean
    end

    def changeset(%__MODULE__{} = struct, attrs) do
      struct
      |> cast(attrs, [:id, :delete])
    end
  end

  defmodule Container do
    use Ecto.Schema
    embedded_schema do
      field :many, {:array, Deletable}
    end
  end

  test "delection of deletable ids from a nested association." do
    nested =
    for {id, delete} <- [{1, false}, {2, true}],
      do: Deletable.changeset(%Deletable{id: id}, %{delete: delete})

    actual =
      change(%Container{})
      |> put_change(:many, nested)
      |> ChangesetX.ids_to_delete_from(:many)

    assert actual == MapSet.new([2])

  end    
end
  
