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

  end
end
  
