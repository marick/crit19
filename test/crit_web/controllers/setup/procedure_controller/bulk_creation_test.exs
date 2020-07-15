defmodule CritWeb.Setup.ProcedureController.BulkCreationTest do
  use CritWeb.ConnCase
  use PhoenixIntegration
  alias CritWeb.Setup.ProcedureController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Schemas

  setup :logged_in_as_setup_manager

  describe "request the bulk creation form" do
    test "renders form", %{conn: conn} do
      conn
      |> get_via_action(:bulk_creation_form)
      |> assert_purpose(show_procedure_creation_form())
    end
  end

  describe "handle bulk creation" do
    test "typical case", %{conn: conn} do
      changes = %{0 => %{name: "proc1",
                         species_ids: [@bovine_id, @equine_id],
                         frequency_id: @once_per_week_frequency_id
                        },
                  3 => %{name: "proc2",
                         species_ids: [@bovine_id]}}
      correct_creation(conn, changing: changes)
      |> assert_purpose(snippet_to_display_procedure())
      |> assert_user_sees(["proc1", "proc2", @bovine, @equine])
      |> assert_user_sees(["once per week", "unlimited"])

      assert [%{name: "proc1"}, %{name: "proc2"}] = 
        Schemas.Procedure.Get.all_by_species(@bovine_id, @institution)
      assert [%{name: "proc1"}] = 
        Schemas.Procedure.Get.all_by_species(@equine_id, @institution)
    end

    test "no species chosen", %{conn: conn} do
      changes = %{0 => %{name: "proc1",
                         species_ids: [@bovine_id, @equine_id],
                         frequency_id: @once_per_week_frequency_id
                        },
                  3 => %{name: "proc2"}}
      
      incorrect_creation(conn, changing: changes)
      |> assert_user_sees(["proc1", "proc2", @bovine, @equine]) # changes retained
      |> assert_user_sees(@at_least_one_species)
      # Correct one not added.
      assert [] = Schemas.Procedure.Get.all_by_species(@bovine_id, @institution)
    end

    test "duplicate name", %{conn: conn} do
      Factory.sql_insert!(:procedure, name: "procedure", species_id: @bovine_id)
      msg = "A procedure named &quot;procedure&quot; already exists for species bovine"
      changes = %{0 => %{name: "procedure",
                         species_ids: [@bovine_id, @equine_id],
                         frequency_id: @once_per_week_frequency_id
                        }}
      incorrect_creation(conn, changing: changes)
      |> assert_user_sees(msg)
    end

    test "a duplicate prevents valid procedures from being inserted",
      %{conn: conn} do
      Factory.sql_insert!(:procedure, name: "duplicate", species_id: @bovine_id)

      changes = %{0 => %{name: "duplicate",
                         species_ids: [@bovine_id, @equine_id],
                         frequency_id: @once_per_week_frequency_id
                        },
                  1 => %{name: "non-duplicate",
                         species_ids: [@bovine_id],
                         frequency_id: @unlimited_frequency_id
                        }}

      incorrect_creation(conn, changing: changes)
      assert [%{name: "duplicate"}] =
        Schemas.Procedure.Get.all_by_species(@bovine_id, @institution)
      assert [] =
        Schemas.Procedure.Get.all_by_species(@equine_id, @institution)
    end

    test "only one error message for a two-species procedure", %{conn: conn} do
      # This is an unfortunate consequence of the insertion being transactional.
      # The view model is split into two schema values, and the transaction fails
      # for the first one.

      Factory.sql_insert!(:procedure, name: "duplicate", species_id: @bovine_id)
      Factory.sql_insert!(:procedure, name: "duplicate", species_id: @equine_id)

      changes = %{0 => %{name: "duplicate",
                         species_ids: [@bovine_id, @equine_id],
                         frequency_id: @once_per_week_frequency_id
                        }}

      incorrect_creation(conn, changing: changes)
      |> assert_user_sees("already exists for species bovine")
      |> refute_user_sees("already exists for species equine")
    end

    test "it is OK if the duplicate name is for a different species", %{conn: conn} do

      Factory.sql_insert!(:procedure, name: "duplicate", species_id: @bovine_id)

      changes = %{0 => %{name: "duplicate",
                         species_ids: [@equine_id],
                         frequency_id: @once_per_week_frequency_id
                        }}

      correct_creation(conn, changing: changes)

      assert [%{name: "duplicate"}] =
        Schemas.Procedure.Get.all_by_species(@bovine_id, @institution)
      assert [%{name: "duplicate"}] =
        Schemas.Procedure.Get.all_by_species(@equine_id, @institution)
    end
  end

  # ----------------------------------------------------------------------------

  defp follow_creation_form(conn, [changing: changes]) do
    get_via_action(conn, :bulk_creation_form)
    |> follow_form(%{procedures: changes})
  end
  
  defp correct_creation(conn, opts) do
    follow_creation_form(conn, opts)
    |> assert_purpose(displaying_procedure_summaries())
  end
  
  defp incorrect_creation(conn, opts) do
    follow_creation_form(conn, opts)
    |> assert_purpose(show_procedure_creation_form())
  end
  
end
