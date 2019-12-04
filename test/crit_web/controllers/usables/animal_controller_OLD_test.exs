defmodule CritWeb.Usables.AnimalControllerOLDTest do
  use CritWeb.ConnCase
  alias CritWeb.Usables.AnimalController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.Schemas.Animal
  alias Crit.Exemplars

  setup :logged_in_as_usables_manager

  describe "bulk create animals" do
    setup do
      act = fn conn, params ->
        post_to_action(conn, :bulk_create, under(:bulk_animal, params))
      end
      [act: act]
    end

    setup do
      assert SqlX.all_ids(Animal) == []
      []
    end

    test "a bad start date is supposed to be impossible", %{conn: conn, act: act} do
      {_names, params} = animal_creation_data()

      IO.puts "Move this"

      bad_params = Map.put(params, "in_service_datestring", "yesterday...")

      assert_raise RuntimeError, fn -> 
        act.(conn, bad_params)
      end
    end

    test "a bad end date is supposed to be impossible", %{conn: conn, act: act} do
      {_names, params} = animal_creation_data()

      IO.puts "Move this"

      bad_params = Map.put(params, "out_of_service_datestring", "2525-13-06")

      assert_raise RuntimeError, fn -> 
        act.(conn, bad_params)
      end
    end
  end

  defp animal_creation_data() do
    {in_service_datestring, out_of_service_datestring} = Exemplars.Date.date_pair() 
    {_species_name, species_id} = Enum.random(AnimalApi.available_species(@institution))
    
    namelist = Factory.unique_names()

    params = %{"names" => Factory.names_to_input_string(namelist),
               "species_id" => species_id,
               "in_service_datestring" => in_service_datestring,
               "out_of_service_datestring" => out_of_service_datestring
              }

    {namelist, params}
  end
end
