defmodule Crit.Usables.Write.ProcedureTest do
  use Crit.DataCase
  alias Crit.Usables.Write

  describe "changeset" do
    test "required fields are checked" do
      errors =
        %Write.Procedure{}
        |> Write.Procedure.changeset(%{})
        |> errors_on

      assert errors.name
    end
  end

  describe "insertion" do
    test "success" do
      attrs = %{"name" => "physical examinination"}
      {:ok, %Write.Procedure{id: _id}} = Write.Procedure.insert(attrs, @institution)
    end

    
    test "attempt to add a duplicate" do
      attrs = %{"name" => "physical examinination"}
      {:ok, _} = Write.Procedure.insert(attrs, @institution)
      {:error, changeset} = Write.Procedure.insert(attrs, @institution)

      refute changeset.valid?
      assert "has already been taken" in errors_on(changeset).name
    end
  end
    

end
