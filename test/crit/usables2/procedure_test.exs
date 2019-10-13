defmodule Crit.Usables.ProcedureTest do
  use Crit.DataCase
  alias Crit.Usables.Procedure

  describe "changeset" do
    test "required fields are checked" do
      errors =
        %Procedure{}
        |> Procedure.changeset(%{})
        |> errors_on

      assert errors.name
    end
  end

  describe "insertion" do
    test "success" do
      attrs = %{"name" => "physical examinination"}
      {:ok, %Procedure{id: _id}} = Procedure.insert(attrs, @institution)
    end

    
    test "attempt to add a duplicate" do
      attrs = %{"name" => "physical examinination"}
      {:ok, _} = Procedure.insert(attrs, @institution)
      {:error, changeset} = Procedure.insert(attrs, @institution)

      refute changeset.valid?
      assert "has already been taken" in errors_on(changeset).name
    end
  end
    

end
