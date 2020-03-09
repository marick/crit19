defmodule CritWeb.Setup.ProcedureViewTest do
  use CritWeb.ConnCase, async: true
  import Phoenix.HTML
  alias CritWeb.Setup.ProcedureView
  alias CritWeb.ViewModels.Procedure.Creation

  describe "specialized error display for procedure creation" do
    test "empty values for name and species produces no errors" do
      input = Creation.starting_changeset()
      actual = ProcedureView.creation_error_tag(input, :species_ids)
      assert [] == actual
    end

    test "show case where no species were chosen" do
      input = Creation.changeset(%Creation{}, %{name: "anything"})
      [actual] = ProcedureView.creation_error_tag(input, :species_ids)
      expected = Creation.legit_error_messages().at_least_one_species
      assert safe_to_string(actual) =~ expected
    end
  end
end
