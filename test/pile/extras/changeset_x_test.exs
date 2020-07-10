defmodule Ecto.ChangesetXTest do
  use ExUnit.Case, async: true
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.ChangesetX

  embedded_schema do
    field :field, :integer
  end

  def data(value), do: %__MODULE__{field: value}


  # -------------Fields and Changes ------------------------------------------------

  test "Working with no change" do
    cs = change(data("old"))
    
    assert ChangesetX.old!(cs, :field) == "old"
    assert_raise KeyError, fn -> ChangesetX.new!(cs, :field) end
    assert ChangesetX.newest!(cs, :field) == "old"
  end

  test "Working with a change" do
    cs = change(data("old"), field: "new")
    
    assert ChangesetX.old!(cs, :field) == "old"
    assert ChangesetX.new!(cs, :field) == "new"
    assert ChangesetX.newest!(cs, :field) == "new"
  end

  test "Working with a bad field" do
    cs = change(data("old"), field: "new")
    
    assert_raise KeyError, fn -> ChangesetX.old!(cs, :bad_field) end
    assert_raise KeyError, fn -> ChangesetX.new!(cs, :bad_field) end
    assert_raise KeyError, fn -> ChangesetX.newest!(cs, :bad_field) end
  end
  
  
  # --------Errors ---------------------------------------------

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

  
  # ------------Groups of changesets--------------------
  # ------------Misc-------------------------------------

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
      |> ChangesetX.ids_marked_for_deletion(:many)

    assert actual == MapSet.new([2])
  end
end
  
