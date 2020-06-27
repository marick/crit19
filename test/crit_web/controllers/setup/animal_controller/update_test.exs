defmodule CritWeb.Setup.AnimalController.UpdateTest do
  use CritWeb.ConnCase
  use PhoenixIntegration
  alias CritWeb.Setup.AnimalController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Setup.AnimalApi
  # alias Crit.Setup.AnimalApi2
  alias Crit.Extras.{AnimalT, ServiceGapT}
  alias CritWeb.ViewModels.Setup, as: VM
  # alias Ecto.Datespan
  import Crit.RepoState
  alias Crit.Exemplars, as: Ex
  

  setup :logged_in_as_setup_manager


  describe "the update form" do
    setup do 
      repo =
        Ex.Bossie.create
        |> service_gap_for("Bossie", starting: @earliest_date)
        |> shorthand()
      [repo: repo]
    end
    
    test "unit test", %{conn: conn, repo: repo} do
      get_via_action(conn, :update_form, to_string(repo.bossie.id))
      |> assert_purpose(form_for_editing_animal())
      |> assert_user_sees(["Bossie", @earliest_iso_date])
    end

    test "details about form structure", %{conn: conn, repo: repo} do
      bossie = VM.Animal.fetch(:one_for_edit, repo.bossie.id, @institution)
      bossie_gap = bossie.service_gaps |> singleton_payload

      params = 
        get_via_action(conn, :update_form, to_string(repo.bossie.id))
        |> fetch_form
        |> animal_params

      params                 |> assert_animal_form(bossie)
      service_gap(params, 0) |> assert_empty_service_gap_form
      service_gap(params, 1) |> assert_service_gap_form(bossie_gap)
    end
  end

  describe "update a single animal" do
    setup do 
      repo =
        Ex.Bossie.create
        |> Ex.Bossie.put_service_gap(reason: "will change")
        |> Ex.Bossie.put_service_gap(reason: "won't change")
        |> Ex.Bossie.put_service_gap(reason: "will delete")
      [repo: repo]
    end

    test "success", %{conn: conn, repo: repo} do
      service_gap_changes = %{
        0 => %{"reason" => "newly added",
               "in_service_datestring" => "2300-01-02",
               "out_of_service_datestring" => "2300-01-03"
              },
        1 => %{"reason" => "replaces: will change"},
        3 => %{"delete" => "true"}
      }
      
      get_via_action(conn, :update_form, repo.bossie.id)
      |> follow_form(%{animal:
           %{name: "new name!",
             service_gaps: service_gap_changes
           }})
      |> assert_purpose(snippet_to_display_animal())
      # Note that service gaps are not displayed as a part of a snippet
      |> assert_user_sees("new name")
      
      # Check that the changes propagate
      animal = VM.Animal.fetch(:one_for_edit, repo.bossie.id, @institution)
      assert_field(animal, name: "new name!")

      [changed, _unchanged, added] = sorted_by_id(animal, :service_gaps)

      assert_field(changed, reason: "replaces: will change")
      assert_fields(added,
        reason: "newly added",
        in_service_datestring: "2300-01-02",
        out_of_service_datestring: "2300-01-03")
    end

    test "a *blank* service gap form is ignored", %{conn: conn, repo: repo} do

      original = VM.Animal.fetch(:one_for_edit, repo.bossie.id, @institution)

      get_via_action(conn, :update_form, repo.bossie.id)
      |> follow_form(%{animal: %{}})
      # There was not a failure (which would render a different snippet)
      |> assert_purpose(snippet_to_display_animal())
      
      VM.Animal.fetch(:one_for_edit, repo.bossie.id, @institution)
      |> assert_copy(original, except: [lock_version: original.lock_version + 1])
    end

    @tag :skip
    test "validation failures produce appropriate messages in the HTML",
      %{conn: conn, repo: repo} do

      changes = %{in_service_datestring: @iso_date_2,
                  out_of_service_datestring: @iso_date_1,
                  service_gaps: %{1 => %{reason: ""}}}
                                                       
      get_via_action(conn, :update_form, repo.bossie.id)
      |> follow_form(%{animal: changes})
      |> assert_purpose(form_for_editing_animal())
      |> assert_user_sees(@date_misorder_message)
      # |> assert_user_sees(@blank_message_in_html)
    end
  end

  describe "handling of the 'add a new service gap' field when there are form errors" do
    # This is tested here because it's easier to check that the right form
    # is displayed than that the more-complex changeset structure is filled out
    # correctly.
    setup do
      %{id: animal_id} = AnimalT.dated(@iso_date_1, @never)
      old_gap = ServiceGapT.dated(animal_id, @iso_date_2, @iso_date_3)
      animal = AnimalApi.updatable!(animal_id, @institution)
      params = AnimalT.unchanged_params(animal)

      [animal: animal, params: params, old_gap: old_gap]
    end

    @tag :skip
    test "only an error in the animal part",
      %{animal: animal, params: unchanged_params, old_gap: old_gap, conn: conn} do

      params =
        unchanged_params
        |> put_in(["out_of_service_datestring"], @iso_date_1)

      post_to_action(conn, [:update, to_string(animal.id)], under(:animal_old, params))
      |> assert_user_sees(@date_misorder_message)
      |> assert_new_service_gap_form(animal)
      |> assert_existing_service_gap_form(animal, old_gap)
    end

    @tag :skip
    test "an error only in the old service gaps",
      %{animal: animal, params: unchanged_params, old_gap: old_gap, conn: conn} do

      params =
        unchanged_params
        |> put_in(["out_of_service_datestring"], @iso_date_1)
        |> put_in(["service_gaps", "1", "out_of_service_datestring"], @iso_date_2)

      post_to_action(conn, [:update, to_string(animal.id)], under(:animal_old, params))
      |> assert_user_sees(@date_misorder_message)
      |> assert_new_service_gap_form(animal)
      |> assert_existing_service_gap_form(animal, old_gap)
    end

    @tag :skip
    test "an error only in the new service gap",
      %{animal: animal, params: unchanged_params, old_gap: old_gap, conn: conn} do

      params =
        unchanged_params
        |> put_in(["service_gaps", "0", "out_of_service_datestring"], @iso_date_2)

      post_to_action(conn, [:update, to_string(animal.id)], under(:animal_old, params))
      |> assert_user_sees(@blank_message_in_html)
      |> assert_new_service_gap_form(animal)
      |> assert_existing_service_gap_form(animal, old_gap)
    end
      
    @tag :skip
    test "errors in the new and old service gaps",
      %{animal: animal, params: unchanged_params, old_gap: old_gap, conn: conn} do
      params =
        unchanged_params
        |> put_in(["service_gaps", "0", "reason"], @iso_date_2)
        |> put_in(["service_gaps", "1", "out_of_service_datestring"], @iso_date_2)

      post_to_action(conn, [:update, to_string(animal.id)], under(:animal_old, params))
      |> assert_user_sees(@date_misorder_message)
      |> assert_user_sees(@blank_message_in_html)
      |> assert_new_service_gap_form(animal)
      |> assert_existing_service_gap_form(animal, old_gap)
    end

    @tag :skip
    test "an error in the new service gap and animal",
      %{animal: animal, params: unchanged_params, old_gap: old_gap, conn: conn} do
      params =
        unchanged_params
        |> put_in(["out_of_service_datestring"], @iso_date_1)
        |> put_in(["service_gaps", "0", "out_of_service_datestring"], @iso_date_2)

      post_to_action(conn, [:update, to_string(animal.id)], under(:animal_old, params))
      |> assert_user_sees(@date_misorder_message)
      |> assert_user_sees(@blank_message_in_html)
      |> assert_new_service_gap_form(animal)
      |> assert_existing_service_gap_form(animal, old_gap)
    end

    @tag :skip
    test "an error in the old service gap and animal",
      %{animal: animal, params: unchanged_params, old_gap: old_gap, conn: conn} do
      params =
        unchanged_params
        |> put_in(["out_of_service_datestring"], @iso_date_1)
        |> put_in(["service_gaps", "1", "out_of_service_datestring"], @iso_date_2)

      post_to_action(conn, [:update, to_string(animal.id)], under(:animal_old, params))
      |> assert_user_sees(@date_misorder_message)
      |> refute_user_sees(@blank_message_in_html)
      |> assert_new_service_gap_form(animal)
      |> assert_existing_service_gap_form(animal, old_gap)
    end
  end

  describe "the common case where there is no existing service gap" do 
    setup do
      %{id: animal_id} = AnimalT.dated(@iso_date_1, @never)
      animal = AnimalApi.updatable!(animal_id, @institution)
      params = AnimalT.unchanged_params(animal)

      [animal: animal, params: params]
    end
    
    @tag :skip
    test "an error in the new service gap and animal",
      %{animal: animal, params: unchanged_params, conn: conn} do
      params =
        unchanged_params
        |> put_in(["out_of_service_datestring"], @iso_date_1)
        |> put_in(["service_gaps", "0", "out_of_service_datestring"], @iso_date_2)

      post_to_action(conn, [:update, to_string(animal.id)], under(:animal_old, params))
      |> assert_user_sees(@date_misorder_message)
      |> assert_user_sees(@blank_message_in_html)
      |> assert_new_service_gap_form(animal)
    end
          
    @tag :skip
    test "an error in just the new service gap",
      %{animal: animal, params: unchanged_params, conn: conn} do
      params =
        unchanged_params
        |> put_in(["service_gaps", "0", "out_of_service_datestring"], @iso_date_2)

      post_to_action(conn, [:update, to_string(animal.id)], under(:animal_old, params))
      |> assert_user_sees(@blank_message_in_html)
      |> assert_new_service_gap_form(animal)
    end
    
    @tag :skip
    test "an error in just the animal",
      %{animal: animal, params: unchanged_params, conn: conn} do
      params =
        unchanged_params
        |> put_in(["out_of_service_datestring"], @iso_date_1)

      post_to_action(conn, [:update, to_string(animal.id)], under(:animal_old, params))
      |> assert_user_sees(@date_misorder_message)
      |> refute_user_sees(@blank_message_in_html)
      |> assert_new_service_gap_form(animal)
    end
          
  end

  defp assert_empty_service_gap_form(params) do
    refute Map.has_key?(params, :id)
    refute Map.has_key?(params, :delete)
    assert_fields(params,
      in_service_datestring: "",
      out_of_service_datestring: "",
      reason: "")
  end

  defp service_gap(container, index) do
    container.service_gaps[index |> to_string |> String.to_atom]
  end

  defp assert_service_gap_form(params, reference_value) do
    assert_params(params, reference_value,
      [:id, :in_service_datestring, :out_of_service_datestring, :reason])
  end

  defp animal_params(%{inputs: %{animal: retval}}), do: retval

  defp assert_animal_form(params, reference_animal) do
    assert_params(params, reference_animal,
      [:name, :lock_version, :in_service_datestring, :out_of_service_datestring])
  end

  defp assert_params(params, source, keys) do
    expected = for k <- keys, do: {k, to_string(Map.get(source, k))}
    assert_fields(params, expected)
  end

  
end
