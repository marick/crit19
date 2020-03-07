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
      params = params([{"procedure", [@bovine_id]}])
      post_to_action(conn, :bulk_create, under(:procedures, params))
      |> assert_purpose(displaying_procedure_summaries())

      
      assert [only] = ProcedureApi.all_by_species(@bovine_id, @institution)
    end

    test "an empty row is ignored", %{conn: conn} do
      params = params([{"procedure", [@bovine_id]},
                       {"", []}])
      post_to_action(conn, :bulk_create, under(:procedures, params))
      |> assert_purpose(displaying_procedure_summaries())

      assert [only] = ProcedureApi.all_by_species(@bovine_id, @institution)
    end

    test "typical case", %{conn: conn} do
      params = params([{"p1", [@bovine_id, @equine_id]},
                       {"p2", [@bovine_id]},
                       {"", []},
                       {"", []},
                       {"", []}])
      post_to_action(conn, :bulk_create, under(:procedures, params))
      |> assert_purpose(displaying_procedure_summaries())

      assert [%{name: "p1"}, %{name: "p2"}] = 
        ProcedureApi.all_by_species(@bovine_id, @institution)
      assert [%{name: "p1"}] = 
        ProcedureApi.all_by_species(@equine_id, @institution)
    end  
    
  end

  defp params(list) do
    one_param = fn name, index_string, species_id_strings -> 
      %{"name" => name, "index" => index_string , "species_ids" => species_id_strings}
    end

    map_entry = fn {{name, species_ids}, index} ->
      species_id_strings = Enum.map(species_ids, &to_string/1)
      index_string = to_string(index)
      {index_string, one_param.(name, index_string, species_id_strings)}
    end
    
    list
    |> Enum.with_index
    |> Enum.map(map_entry)
    |> Map.new
  end
end
