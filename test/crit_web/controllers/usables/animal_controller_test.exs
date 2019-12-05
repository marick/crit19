defmodule CritWeb.Usables.AnimalControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.Usables.AnimalController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Usables.FieldConverters.ToNameList
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.Schemas.{Animal, ServiceGap}
  alias CritWeb.Audit
  alias Crit.Exemplars

  # All controller tests are end-to-end tests.

  setup :logged_in_as_usables_manager

  test "fetching a set of animals", %{conn: conn} do
    %{name: name1} = Factory.sql_insert!(:animal, @institution)
    %{name: name2} = Factory.sql_insert!(:animal, @institution)
    
      get_via_action(conn, :index)
      |> assert_purpose(displaying_animal_summaries())
      |> assert_user_sees(name1)
      |> assert_user_sees(name2)
  end

  describe "request the bulk creation form" do
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
        post_to_action(conn, :bulk_create, under(:bulk_animal, params))
      end
      [act: act]
    end

    setup do
      # It's relatively easy to accidentally put persistent data into
      # the test database, so this checks for that
      assert SqlX.all_ids(Animal) == []
      []
    end

    test "success case", %{conn: conn, act: act} do
      {names, params} = bulk_creation_params()
      conn = act.(conn, params)
      
      assert_purpose conn, displaying_animal_summaries()

      assert length(SqlX.all_ids(Animal)) == length(names)
      assert_user_sees(conn, Enum.at(names, 0))
      assert_user_sees(conn, Enum.at(names, -1))
    end

    test "renders errors when data is invalid", %{conn: conn, act: act} do
      {_names, params} = bulk_creation_params()

      bad_params = Map.put(params, "names", " ,     ,")

      act.(conn, bad_params)
      |> assert_purpose(form_for_creating_new_animal())

      # error messages
      |> assert_user_sees(ToNameList.no_names_error_message())
      # Fields retain their old values.
      |> assert_user_sees(bad_params["names"])
    end

    test "an audit record is created", %{conn: conn, act: act} do
      {_names, params} = bulk_creation_params()
      conn = act.(conn, params)

      {:ok, audit} = latest_audit_record(conn)

      ids = SqlX.all_ids(Animal)
      typical_animal = AnimalApi.updatable!(hd(ids), @institution)

      assert audit.event == Audit.events.created_animals
      assert audit.event_owner_id == user_id(conn)
      assert audit.data.ids == ids
      assert audit.data.in_service_date == typical_animal.in_service_date
      assert audit.data.out_of_service_date == typical_animal.out_of_service_date
    end
  end


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

      IO.puts "Service gap deletion does not yet work."
      [changed, _deleted, added] =
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


  defp bulk_creation_params() do
    {in_service_datestring, out_of_service_datestring} = Exemplars.Date.date_pair()
    namelist = Factory.unique_names()

    params = %{"names" => Factory.names_to_input_string(namelist),
               "species_id" => Factory.some_species_id,
               "in_service_datestring" => in_service_datestring,
               "out_of_service_datestring" => out_of_service_datestring
              }

    {namelist, params}
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
