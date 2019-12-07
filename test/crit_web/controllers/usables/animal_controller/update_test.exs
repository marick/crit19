defmodule CritWeb.Usables.AnimalController.UpdateTest do
  use CritWeb.ConnCase
  alias CritWeb.Usables.AnimalController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.Schemas.ServiceGap
  alias Crit.Exemplars
  alias Crit.X.AnimalX

  setup :logged_in_as_usables_manager

  describe "update a single animal" do
    setup do
      id = Exemplars.Available.animal_id(name: "original name")
      _will_changed = Factory.sql_insert!(:service_gap, [animal_id: id], @institution)
      _will_vanish = Factory.sql_insert!(:service_gap, [animal_id: id], @institution)
      
      [animal_id: id]
    end
    
    test "success", %{conn: conn, animal_id: animal_id} do
      new_service_gap = %{"in_service_date" => "2300-01-02",
                          "out_of_service_date" => "2300-01-03",
                          "reason" => "newly added"
                         }
      
      params =
        animal_id
        |> AnimalApi.updatable!(@institution)
        |> AnimalX.params
        # change a field in the animal itself
        |> Map.put("name", "new name")
        # change a field in one of the service gaps
        |> put_in(["service_gaps", "0", "reason"], "fixored reason")
        # delete the other 
        |> put_in(["service_gaps", "1", "delete"], "true")
        |> put_in(["service_gaps", "2"], new_service_gap)

      post_to_action(conn, [:update, to_string(animal_id)], under(:animal, params))
      |> assert_purpose(snippet_to_display_animal())
      # Note that service gaps are not displayed as a part of a snippet
      |> assert_user_sees("new name")
      
      # Check that the changes propagate
      animal = AnimalApi.updatable!(animal_id, @institution)
      assert_field(animal, name: "new name")

      [changed, added] =
        animal.service_gaps |> Enum.sort_by(fn gap -> gap.id end)

      assert_field(changed,
        reason: "fixored reason")
      assert_fields(added,
        reason: "newly added",
        span: ServiceGap.span(~D[2300-01-02], ~D[2300-01-03]))
    end

    test "update failures produce appropriate annotations", 
    %{conn: conn, animal_id: animal_id} do

      Exemplars.Available.animal_id(name: "name clash")

      params =
        animal_id
        |> AnimalApi.updatable!(@institution)
        |> AnimalX.params
        # Dates are in wrong order
        |> put_in(["in_service_datestring"], @later_iso_date)
        |> put_in(["out_of_service_datestring"], @iso_date)
        # ... and there's an error in a service gap change.
        |> put_in(["service_gaps", "0", "out_of_service_date"], "nver")

      post_to_action(conn, [:update, to_string(animal_id)], under(:animal, params))
      |> assert_purpose(form_for_editing_animal())
      |> assert_user_sees("should not be before the start date")
      |> assert_user_sees("is invalid")
    end
  end
end
