defmodule CritWeb.Setup.AnimalController.BulkCreationTest do
  use CritWeb.ConnCase
  use PhoenixIntegration
  alias CritWeb.Setup.AnimalController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Schemas
  alias CritWeb.Audit
  alias Crit.Exemplars, as: Ex

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
      |> form_inputs(:bulk_animal)
      |> assert_fields(in_service_datestring: @today,
                       out_of_service_datestring: @never,
                       species_id: to_string(@bovine_id),
                       names: "\n")
    end
  end

  describe "bulk create animals" do
    test "success case", %{conn: conn} do
      changes = %{names: "bad ass animal, animal of bliss"}

      correct_creation(conn, changing: changes)
      |> assert_purpose(displaying_animal_summaries())
      |> assert_user_sees("animal of bliss")
      |> assert_user_sees("bad ass animal")

      names = Schemas.Animal.Get.inadequate_all(@institution) |> EnumX.names
      assert names == ["animal of bliss", "bad ass animal"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      changes = %{names: " ,     ,"}

      inputs = 
        incorrect_creation(conn, changing: changes)
        |> assert_user_sees(@no_valid_names_message)
        |> form_inputs(:bulk_animal)


      inputs
      |> assert_fields(in_service_datestring: @today,
                       out_of_service_datestring: @never,
                       species_id: to_string(@bovine_id))

      # Because names are collected in a text area, there can be whitespace
      # before the text the user types. So this test trims.
      assert String.trim(inputs.names) == String.trim(changes.names)
    end


    test "rejects duplicate names", %{conn: conn} do
      Ex.Bossie.create
      changes = %{names: "Bossie"}
      expected = html_quoted(~s[An animal named "Bossie" is already in service])

      incorrect_creation(conn, changing: changes)
      |> assert_user_sees(expected)
    end
    

    # This test no longer works because `follow_form` doesn't preserve
    # the audit record pid that's stashed in the `conn`. However, that
    # pid should probably be per-institution anyway, to be accessed
    # via the InstitutionApi.
    @tag :skip
    test "an audit record is created", %{conn: conn} do
      changes = %{names: "bad ass animal, animal of bliss"}

      correct_creation(conn, changing: changes)

      {:ok, audit} = latest_audit_record(conn)
      ids = SqlT.all_ids(Schemas.Animal)

      assert_fields(audit,
        event: Audit.events.created_animals,
        event_owner_id: user_id(conn))

      assert_fields(audit.data,
        ids: ids,
        names: changes.names
        # put_in_service: params["in_service_datestring"],
        # leaves_service: params["out_of_service_datestring"]
      )        
    end
  end

  # ----------------------------------------------------------------------------

  defp follow_creation_form(conn, [changing: changes]) do
    get_via_action(conn, :bulk_create_form)
    |> follow_form(%{bulk_animal: changes})
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
