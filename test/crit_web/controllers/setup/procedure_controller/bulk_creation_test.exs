defmodule CritWeb.Setup.ProcedureController.BulkCreationTest do
  use CritWeb.ConnCase
  alias CritWeb.Setup.ProcedureController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Setup.ProcedureApi
  # alias Crit.Setup.Schemas.Procedure
  # alias CritWeb.Audit
  # alias Crit.Exemplars

  setup :logged_in_as_setup_manager

  describe "request the bulk creation form" do
    test "renders form", %{conn: conn} do
      conn
      |> get_via_action(:bulk_creation_form)
      |> assert_purpose(show_procedure_creation_form())
    end
  end

  describe "handle bulk creation" do
    test "successful creation of one procedure", %{conn: conn} do
      params = %{"0" => %{"name" => "procedure", "index" => "0",
                          "species_ids" => [to_string(@bovine_id)]}}
      IO.inspect under(:procedures, params)
      post_to_action(conn, :bulk_create, under(:procedures, params))
      |> assert_purpose(displaying_procedure_summaries())

      
      assert [only] = ProcedureApi.all_by_species(@bovine_id, @institution)
    end
  end

  
end
