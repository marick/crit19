defmodule CritWeb.Usables.AnimalControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.Usables.AnimalController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Usables
  alias Crit.Usables.Animal
  alias Crit.Sql

  setup :logged_in_as_usables_manager

  describe "new animal" do
    test "renders form", %{conn: conn} do
      conn
      |> get_via_action(:new)
      |> assert_purpose(form_for_creating_new_animal())
    end
  end

  defp animal_creation_data() do
    {start_date, end_date} = Factory.date_pair()
    {species_name, species_id} = Enum.random(Usables.available_species(@institution))
    
    names =
      Faker.Cat.name()
      |> List.duplicate(Faker.random_between(1, 200))
      |> Enum.with_index
      |> Enum.map(fn {name, index} -> "#{name}_!_#{index}" end)

    params = %{"names" => Enum.join(names, ", "), 
               "species_id" => species_id,
               "species_name_for_tests" => species_name,
               "start_date" => start_date,
               "end_date" => end_date
              }

    {names, params}
  end

  describe "create animal" do
    setup do
      act = fn conn, params ->
        post_to_action(conn, :create, under(:animal, params))
      end
      [act: act]
    end

    setup do
      assert Sql.all(Animal, @institution) == []
      []
    end

    test "success case", %{conn: conn, act: act} do
      {names, params} = animal_creation_data()
      conn = act.(conn, params)
      
      assert_purpose conn, displaying_animal_summaries()

      assert length(Sql.all(Animal, @institution)) == length(names)
      assert_user_sees(conn, Enum.at(names, 0))
      assert_user_sees(conn, Enum.at(names, -1))
      assert_user_sees(conn, params["species_name_for_tests"])
    end

    @tag :skip
    test "renders errors when data is invalid", %{conn: conn, act: act} do
      conn = act.(conn, Factory.string_params_for(:animal, name: ""))

      assert_purpose(conn, form_for_creating_new_animal())
      assert_user_sees(conn, standard_blank_error())
    end

    @tag :skip
    test "an audit record is created", %{conn: conn, act: act} do
      params = Factory.string_params_for(:animal)
      act.(conn, params)

      assert {:ok, audit} = Crit.Audit.ToMemory.Server.latest(conn.assigns.audit_pid)

      assert audit.event == "created animal"
      assert audit.event_owner_id == user_id(conn)
      assert audit.data.name == params["animal_id"]
      assert audit.data.id == params["id"]
      assert audit.data.service_gaps == [:start, :end]
    end
  end

  def redirected_to_new_animal_form?(conn),
    do: redirected_to(conn) == UnderTest.path(:new)
end
