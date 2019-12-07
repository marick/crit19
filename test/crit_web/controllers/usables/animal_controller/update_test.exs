defmodule CritWeb.Usables.AnimalController.UpdateTest do
  use CritWeb.ConnCase
  alias CritWeb.Usables.AnimalController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.Schemas.ServiceGap
  alias Crit.Exemplars

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
        |> animal_to_params
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

    @tag :skip
    test "update failures produce appropriate annotations" do
    end
  end
  
  defp animal_to_params(animal) do
    base = 
      %{"in_service_datestring" => animal.in_service_datestring,
        "lock_version" => to_string(animal.lock_version),
        "name" => animal.name,
        "out_of_service_datestring" => animal.out_of_service_datestring,
       }
    service_gaps =
      Enum.reduce(Enum.with_index(animal.service_gaps), %{}, fn {sg, i}, acc ->
        Map.put(acc,
          to_string(i),
          %{"id" => to_string(sg.id),
            "in_service_date" => Date.to_iso8601(sg.span.first),
            "out_of_service_date" => Date.to_iso8601(sg.span.last),
            "reason" => sg.reason,
            "delete" => "false"
          })
      end)

    Map.put(base, "service_gaps", service_gaps)
  end
end
