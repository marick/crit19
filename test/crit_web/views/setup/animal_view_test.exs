defmodule CritWeb.Setup.AnimalViewTest do
  use CritWeb.ConnCase, async: true
  alias Crit.Setup.Schemas.Animal
  import Phoenix.HTML.Form
  import Phoenix.HTML
  alias CritWeb.Setup.AnimalView

  describe "Showing of nested service gaps in initial form" do
    defp to_form(animal) do
      changeset = Animal.form_changeset(animal)
      form = form_for(changeset, "unused")
      AnimalView.nested_service_gap_forms(form, changeset)
      |> safe_to_string
    end

    setup do
      only_addition_animal = Factory.build(:animal, id: "animalid", service_gaps: [])
      service_gap = Factory.build(:service_gap, id: "sgid")
      addition_and_update = %{only_addition_animal | service_gaps: [service_gap]}
      
      [only_addition: only_addition_animal, addition_and_update: addition_and_update]
    end
    
    test "headings when there is no service gap to edit",
      %{only_addition: only_addition} do
      html = to_form(only_addition)
      assert html =~ "Add a gap"
      refute html =~ "Edit or delete" # no existing changesets
    end

    test "headings when there is a service gap to edit", %{addition_and_update: addition_and_update} do
      html = to_form(addition_and_update)
      assert html =~ "Add a gap"
      assert html =~ "Edit or delete"
    end

    test "that there are distinct ids for the different subforms", %{addition_and_update: addition_and_update} do
      html = to_form(addition_and_update)

      assert html =~ ~S[class="ui calendar" id="in_service_datestring__animalid_and_new_calendar"]
      assert html =~ ~S[class="ui calendar" id="out_of_service_datestring__animalid_sgid_calendar"]
    end
  end
end
