defmodule CritWeb.Usables.AnimalControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.Usables.AnimalController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Usables.FieldConverters.ToNameList
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.Schemas.Animal
  alias CritWeb.Audit
  alias Crit.Exemplars

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

  describe "bulk create animals" do
    setup do
      act = fn conn, params ->
        post_to_action(conn, :bulk_create, under(:bulk_creation, params))
      end
      [act: act]
    end

    setup do
      assert SqlX.all_ids(Animal) == []
      []
    end

    test "success case", %{conn: conn, act: act} do
      {names, params} = animal_creation_data()
      conn = act.(conn, params)
      
      assert_purpose conn, displaying_animal_summaries()

      assert length(SqlX.all_ids(Animal)) == length(names)
      assert_user_sees(conn, Enum.at(names, 0))
      assert_user_sees(conn, Enum.at(names, -1))
    end

    test "renders errors when data is invalid", %{conn: conn, act: act} do
      {_names, params} = animal_creation_data()

      bad_params = Map.put(params, "names", " ,     ,")

      act.(conn, bad_params)
      |> assert_purpose(form_for_creating_new_animal())

      # error messages
      |> assert_user_sees(ToNameList.no_names_error_message())
      # Fields retain their old values.
      |> assert_user_sees(bad_params["names"])
    end

    test "a bad start date is supposed to be impossible", %{conn: conn, act: act} do
      {_names, params} = animal_creation_data()

      bad_params = Map.put(params, "in_service_date", "yesterday...")

      assert_raise RuntimeError, fn -> 
        act.(conn, bad_params)
      end
    end

    test "a bad end date is supposed to be impossible", %{conn: conn, act: act} do
      {_names, params} = animal_creation_data()

      bad_params = Map.put(params, "out_of_service_date", "2525-13-06")

      assert_raise RuntimeError, fn -> 
        act.(conn, bad_params)
      end
    end

    test "an audit record is created", %{conn: conn, act: act} do
      {_names, params} = animal_creation_data()
      conn = act.(conn, params)

      {:ok, audit} = latest_audit_record(conn)

      ids = SqlX.all_ids(Animal)
      typical_animal = one_of_these_as_showable_animal(ids)

      assert audit.event == Audit.events.created_animals
      assert audit.event_owner_id == user_id(conn)
      assert audit.data.ids == ids
      assert audit.data.in_service_date == typical_animal.in_service_date
      assert audit.data.out_of_service_date == typical_animal.out_of_service_date
    end
  end

  describe "update" do
    setup do
      [id: Exemplars.Available.animal_id(name: "OLD NAME")]
    end

    test "name change", %{conn: conn, id: id} do
      assert animal_name(id) == "OLD NAME" 
      conn =
        post_to_action(conn, [:update, id], under(:animal, %{"name" => "newname"}))
      assert animal_name(id) == "newname"

      conn
      |> assert_purpose(snippet_to_display_animal())
      |> assert_user_sees("newname")
    end

    test "duplicate name change", %{conn: conn, id: id} do
      Exemplars.Available.animal_id(name: "already exists")
      conn =
        post_to_action(conn, [:update, id], under(:animal, %{"name" => "already exists"}))
      assert animal_name(id) == "OLD NAME"

      conn
      |> assert_purpose(form_for_editing_animal())
      |> assert_user_sees("already exists")
    end
  end

  describe "index" do
    test "fetching two", %{conn: conn} do
      should_sort_second = "ZZZZZZ"
      should_sort_first = "aaaaaa"
      Exemplars.Available.animal_id(name: should_sort_second)
      Exemplars.Available.animal_id(name: should_sort_first)

      get_via_action(conn, :index)
      |> assert_purpose(displaying_animal_summaries())
      |> assert_user_sees(should_sort_first)
      |> assert_user_sees(should_sort_second)
      # Note that the actual test of ordering is at the `crit` level
    end
  end

  
  defp animal_name(id), do: AnimalApi.showable!(id, @institution).name

  defp animal_creation_data() do
    {in_service_date, out_of_service_date} = Exemplars.Date.date_pair() 
    {_species_name, species_id} = Enum.random(AnimalApi.available_species(@institution))
    
    namelist = Factory.unique_names()

    params = %{"names" => Factory.names_to_input_string(namelist),
               "species_id" => species_id,
               "in_service_date" => in_service_date,
               "out_of_service_date" => out_of_service_date
              }

    {namelist, params}
  end

  defp one_of_these_as_showable_animal([id | _]) do 
    AnimalApi.showable!(id, @institution)
  end
end
