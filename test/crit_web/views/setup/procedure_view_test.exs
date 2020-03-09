defmodule CritWeb.Setup.ProcedureViewTest do
  use CritWeb.ConnCase, async: true
  alias Crit.Setup.Schemas.Procedure
  alias CritWeb.Setup.ProcedureView
  alias CritWeb.ViewModels.Procedure.Creation

  describe "specialized error display for procedure creation" do
    test "empty values for name and species produces no errors" do
      input = Creation.starting_changeset()
      actual = ProcedureView.creation_error_tag(input)
      assert [] == actual
    end

    test "show case where no species were chosen" do
      input = Creation.changeset(%Creation{}, %{name: "anything"})
      [{:safe, actual}] = ProcedureView.creation_error_tag(input) |> IO.inspect
    end
  end
end
