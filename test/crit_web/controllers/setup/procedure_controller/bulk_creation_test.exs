defmodule CritWeb.Setup.ProcedureController.BulkCreationTest do
  use CritWeb.ConnCase
  alias CritWeb.Setup.ProcedureController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Setup.ProcedureApi

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
      params = params([{"proc1", [@bovine_id, @equine_id]},
                       {"proc2", [@bovine_id]},
                       {"", []},
                       {"", []},
                       {"", []}])
      post_to_action(conn, :bulk_create, under(:procedures, params))
      |> assert_purpose(displaying_procedure_summaries())
      |> assert_purpose(snippet_to_display_procedure())
      |> assert_user_sees(["proc1", "proc2", @bovine, @equine])

      assert [%{name: "proc1"}, %{name: "proc2"}] = 
        ProcedureApi.all_by_species(@bovine_id, @institution)
      assert [%{name: "proc1"}] = 
        ProcedureApi.all_by_species(@equine_id, @institution)
    end

    test "no species chosen", %{conn: conn} do
      params = %{"0" => %{"name" => "proc1", "index" => "0"},
                 "1" => %{"name" => "proc2", "index" => "1",
                                     "species_ids" => [to_string @bovine_id]},
                 "2" => %{"name" => "", "index" => "2"}}
      post_to_action(conn, :bulk_create, under(:procedures, params))
      |> assert_purpose(show_procedure_creation_form())   # again
      |> assert_user_sees(["proc1", "proc2", @bovine, @equine])
      |> assert_user_sees(@at_least_one_species)
      # Correct one not added.
      assert [] = ProcedureApi.all_by_species(@bovine_id, @institution)
    end

    test "duplicate name", %{conn: conn} do
      params = params([{"procedure", [@bovine_id]}])
      post_to_action(conn, :bulk_create, under(:procedures, params))
      |> assert_purpose(displaying_procedure_summaries())

      post_to_action(conn, :bulk_create, under(:procedures, params))
      |> assert_purpose(show_procedure_creation_form())
      |> assert_user_sees(@already_taken)
    end

    test "a duplicate prevents valid procedures from being inserted",
      %{conn: conn} do
      
      first_params = params([{"duplicate", [@bovine_id]}])
      post_to_action(conn, :bulk_create, under(:procedures, first_params))
      |> assert_purpose(displaying_procedure_summaries())

      second_params = params([{"duplicate", [@bovine_id]},
                              {"non-duplicate", [@bovine_id]}])
      post_to_action(conn, :bulk_create, under(:procedures, second_params))
      |> assert_purpose(show_procedure_creation_form())
      |> assert_user_sees(@already_taken)

      assert [%{name: "duplicate"}] =
        ProcedureApi.all_by_species(@bovine_id, @institution)
    end

    test "only one error message for a two-species procedure",
      %{conn: conn} do

      params = params([{"duplicate", [@bovine_id, @equine_id]}])
      post_to_action(conn, :bulk_create, under(:procedures, params))
      
      html =
        post_to_action(conn, :bulk_create, under(:procedures, params))
        |> html_response(200)

      assert [[@already_taken]] == Regex.scan(Regex.compile!(@already_taken), html)
    end

    test "two duplicate names in same form", 
    %{conn: conn} do

      params = params([{"duplicate 1", [@bovine_id, @equine_id]},
                       {"duplicate 2", [@bovine_id, @equine_id]}])
      post_to_action(conn, :bulk_create, under(:procedures, params))
      
      html =
        post_to_action(conn, :bulk_create, under(:procedures, params))
        |> html_response(200)

      # Because the error is caught by a database constraint, the error
      # message only appears in the first form.

      regex = Regex.compile!(@already_taken <> ".*duplicate 2", "s")
      assert [[_]] = Regex.scan(regex, html)
    end

    test "it is OK if the duplicate name is for a different species",
      %{conn: conn} do

      first_params = params([{"duplicate", [@bovine_id]}])
      post_to_action(conn, :bulk_create, under(:procedures, first_params))
      |> assert_purpose(displaying_procedure_summaries())

      second_params = params([{"duplicate", [@equine_id]}])
      post_to_action(conn, :bulk_create, under(:procedures, second_params))
      |> assert_purpose(displaying_procedure_summaries())

      assert [%{name: "duplicate"}] =
        ProcedureApi.all_by_species(@bovine_id, @institution)
      assert [%{name: "duplicate"}] =
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
