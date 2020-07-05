defmodule CritWeb.Setup.AnimalController.BulkCreationTest do
  use CritWeb.ConnCase
  use PhoenixIntegration
  alias CritWeb.Setup.AnimalController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Setup.Schemas
  alias CritWeb.Audit
  alias Crit.Exemplars

  setup :logged_in_as_setup_manager

  describe "request the bulk creation form" do
    test "renders form", %{conn: conn} do
      conn
      |> get_via_action(:bulk_create_form)
      |> assert_purpose(form_for_creating_new_animal())
      |> assert_user_sees(@today)
      |> assert_user_sees(@never)
      |> assert_user_sees(@bovine)
    end

    test "details about form structure", %{conn: conn} do
      get_via_action(conn, :bulk_create_form)
      |> form_inputs(:bulk_animal_new)
      |> assert_fields(in_service_datestring: @today,
                       out_of_service_datestring: @never,
                       species_id: to_string(@bovine_id),
                       names: "\n")
    end
  end

  describe "bulk create animals" do
    setup do
      # It's relatively easy to accidentally put persistent data into
      # the test database, so this checks for that
      assert SqlT.all_ids(Schemas.Animal) == []
      :ok
    end

    @tag :skip
    test "success case", %{conn: conn, act: act} do
      {names, params} = bulk_creation_params()
      conn = act.(conn, params)
      
      assert_purpose conn, displaying_animal_summaries()

      assert length(SqlT.all_ids(Schemas.Animal)) == length(names)
      assert_user_sees(conn, Enum.at(names, 0))
      assert_user_sees(conn, Enum.at(names, -1))
    end

    @tag :skip
    test "renders errors when data is invalid", %{conn: conn} do
      changes = %{names: " ,     ,"}
      
      incorrect_creation(conn, changing: changes)
      |> assert_user_sees(@no_valid_names_message)
      |> form_inputs(:bulk_animal_new)
      |> assert_fields(in_service_datestring: @today,
                       out_of_service_datestring: @never,
                       species_id: to_string(@bovine_id),
                       names: changes.names)
    end

    @tag :skip
    test "an audit record is created", %{conn: conn, act: act} do
      {_names, params} = bulk_creation_params()
      conn = act.(conn, params)

      {:ok, audit} = latest_audit_record(conn)

      ids = SqlT.all_ids(Schemas.Animal)

      assert_fields(audit,
        event: Audit.events.created_animals,
        event_owner_id: user_id(conn))

      assert_fields(audit.data,
        ids: ids,
        names: params["names"],
        put_in_service: params["in_service_datestring"],
        leaves_service: params["out_of_service_datestring"]
      )        
    end
  end

  defp bulk_creation_params() do
    {in_service_datestring, out_of_service_datestring} = Exemplars.Date.date_pair()
    namelist = Factory.unique_names()

    params = %{"names" => Factory.names_to_input_string(namelist),
               "species_id" => Factory.some_species_id,
               "in_service_datestring" => in_service_datestring,
               "out_of_service_datestring" => out_of_service_datestring,
               "institution" => @institution
              }

    {namelist, params}
  end

  # ----------------------------------------------------------------------------

  defp follow_creation_form(conn, [changing: changes]) do
    get_via_action(conn, :bulk_create_form)
    |> follow_form(%{bulk_animal_new: changes})
  end
  
  defp correct_creation(conn, opts) do
    follow_creation_form(conn, opts)
    |> assert_purpose(displaying_animal_summaries())
  end
  
  defp incorrect_creation(conn, opts) do
    follow_creation_form(conn, opts)
    |> assert_purpose(form_for_creating_new_animal())
  end
end
