defmodule CritWeb.Usables.AnimalViewTest do
  use CritWeb.ConnCase, async: true
  alias Crit.Usables.Schemas.Animal
  import Phoenix.HTML.Form
  import Phoenix.HTML
  alias CritWeb.Usables.AnimalView

  describe "Showing of nested service gaps" do
    defp to_form(animal) do
      changeset = Animal.update_changeset(animal, %{})
      form = form_for(changeset, "unused")
      AnimalView.nested_service_gap_forms(form, changeset)
      |> safe_to_string
    end

    setup do
      no_gap_animal = Factory.build(:animal, id: "animalid")
      service_gap = Factory.build(:service_gap, id: "sgid")
      gap_animal = %{no_gap_animal | service_gaps: [service_gap]}
      
      [no_gaps: no_gap_animal, gaps: gap_animal]
    end
    
    test "headings when there is no service gap to edit", %{no_gaps: no_gaps} do
      html = to_form(no_gaps)
      assert html =~ "Add a gap"
      refute html =~ "Edit or delete" # no existing changesets
    end

    test "headings when there is a service gap to edit", %{gaps: gaps} do
      html = to_form(gaps)
      assert html =~ "Add a gap"
      assert html =~ "Edit or delete" # no existing changesets
    end

    test "that there are distinct ids for the different subforms", %{gaps: gaps} do
      html = to_form(gaps)

      assert html =~ ~S[class="ui calendar" id="in_service_datestring__animalid_and_new_calendar"]
      assert html =~ ~S[class="ui calendar" id="out_of_service_datestring__animalid_sgid_calendar"]
    end
  end
end
