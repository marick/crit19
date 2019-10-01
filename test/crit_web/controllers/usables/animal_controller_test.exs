defmodule CritWeb.Usables.AnimalControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.Usables.AnimalController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Usables
  alias Crit.Usables.Write.{DateComputers, NameListComputers}
  alias Crit.Usables.Read

  setup :logged_in_as_usables_manager

  describe "bulk creation form" do
    test "renders form", %{conn: conn} do
      conn
      |> get_via_action(:bulk_create_form)
      |> assert_purpose(form_for_creating_new_animal())
      |> assert_user_sees(@today)
      |> assert_user_sees(@never)
      |> assert_user_sees(@bovine)

    end
  end

  defp animal_creation_data() do
    {start_date, end_date} = Factory.date_pair()
    {_species_name, species_id} = Enum.random(Usables.available_species(@institution))
    
    names =
      Faker.Cat.name()
      |> List.duplicate(Faker.random_between(1, 200))
      |> Enum.with_index
      |> Enum.map(fn {name, index} -> "#{name}_!_#{index}" end)

    params = %{"names" => Enum.join(names, ", "), 
               "species_id" => species_id,
               "start_date" => start_date,
               "end_date" => end_date
              }

    {names, params}
  end

  describe "bulk create animals" do
    setup do
      act = fn conn, params ->
        post_to_action(conn, :bulk_create, under(:bulk_animal, params))
      end
      [act: act]
    end

    setup do
      assert SqlX.all_ids(Read.Animal) == []
      []
    end

    test "success case", %{conn: conn, act: act} do
      {names, params} = animal_creation_data()
      conn = act.(conn, params)
      
      assert_purpose conn, displaying_animal_summaries()

      assert length(SqlX.all_ids(Read.Animal)) == length(names)
      assert_user_sees(conn, Enum.at(names, 0))
      assert_user_sees(conn, Enum.at(names, -1))
    end

    test "renders errors when data is invalid", %{conn: conn, act: act} do
      {_names, params} = animal_creation_data()

      bad_params =
        params 
        |> Map.put("names", " ,     ,")
        |> Map.put("start_date", "yesterday...")
        |> Map.put("end_date", "2525-05-06")

      act.(conn, bad_params)
      |> assert_purpose(form_for_creating_new_animal())

      # error messages
      |> assert_user_sees(DateComputers.parse_error_message())
      |> assert_user_sees(NameListComputers.no_names_error_message())
      # Fields retain their old values.
      |> assert_user_sees(bad_params["names"])
      |> assert_user_sees(bad_params["start_date"])
      |> assert_user_sees(bad_params["end_date"])
    end

    test "an audit record is created", %{conn: conn, act: act} do
      {_names, params} = animal_creation_data()
      conn = act.(conn, params)

      {:ok, audit} = latest_audit_record(conn)

      ids = SqlX.all_ids(Read.Animal)
      typical_animal = one_of_these_as_showable_animal(ids)

      assert audit.event == "created animals"
      assert audit.event_owner_id == user_id(conn)
      assert audit.data.ids == ids
      assert audit.data.in_service_date == typical_animal.in_service_date
      assert audit.data.out_of_service_date == typical_animal.out_of_service_date
    end
  end

  defp one_of_these_as_showable_animal([id | _]) do 
    Usables.get_complete_animal!(id, @institution)
  end
end
