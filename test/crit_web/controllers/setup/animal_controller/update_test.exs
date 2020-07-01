defmodule CritWeb.Setup.AnimalController.UpdateTest do
  use CritWeb.ConnCase
  use PhoenixIntegration
  alias CritWeb.Setup.AnimalController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Setup.AnimalApi
  alias Crit.Extras.AnimalT
  alias CritWeb.ViewModels.Setup, as: VM
  import Crit.RepoState
  alias Crit.Exemplars, as: Ex
  

  setup :logged_in_as_setup_manager

  # ----------------------------------------------------------------------------

  describe "the update form" do
    setup do 
      repo =
        Ex.Bossie.create
        |> service_gap_for("Bossie", name: "sg", starting: @earliest_date)
        |> load_completely
        |> shorthand
      [repo: repo]
    end
    
    test "unit test", %{conn: conn, repo: repo} do
      get_via_action(conn, :update_form, to_string(repo.bossie.id))
      |> assert_purpose(form_for_editing_animal())
      |> assert_user_sees(["Bossie", @earliest_iso_date])
    end

    test "details about form structure", %{conn: conn, repo: repo} do
      inputs = 
        get_via_action(conn, :update_form, repo.bossie.id)
        |> form_inputs(:animal)

      inputs                 |> assert_animal_form_for(repo.bossie)
      service_gap(inputs, 0) |> assert_empty_service_gap_form
      service_gap(inputs, 1) |> assert_service_gap_form_for(repo.sg)
    end
  end

  # ----------------------------------------------------------------------------
  describe "update a single animal" do
    setup do 
      repo =
        Ex.Bossie.create
        |> Ex.Bossie.put_service_gap(reason: "will change")
        |> Ex.Bossie.put_service_gap(reason: "won't change")
        |> Ex.Bossie.put_service_gap(reason: "will delete")
        |> load_completely
        |> shorthand
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

    test "validation failures produce appropriate messages in the HTML",
      %{conn: conn, repo: repo} do

      changes = %{in_service_datestring: @iso_date_2,
                  out_of_service_datestring: @iso_date_1,
                  service_gaps: %{1 => %{reason: ""}}}
                                                       
      get_via_action(conn, :update_form, repo.bossie.id)
      |> follow_form(%{animal: changes})
      |> assert_purpose(form_for_editing_animal())
      |> assert_user_sees(@date_misorder_message)
      |> assert_user_sees(@blank_message_in_html)
    end
  end


  # ----------------------------------------------------------------------------
  describe "handling of the 'add a new service gap' field when there are form errors" do
    # This is tested here because it's easier to check that the right form
    # is displayed than that the more-complex changeset structure is filled out
    # correctly.
    setup do
      repo =
        empty_repo(@equine_id)
        |> animal("Jake", available: Ex.Datespan.named(:widest_infinite))
        |> service_gap_for("Jake", name: "sg", ending: @date_2)
        |> shorthand

      [repo: repo]
    end

    test "only an error in the animal part", %{conn: conn, repo: repo} do
      same_as_in_service = Ex.Datespan.in_service_datestring(:widest_infinite)
      changes = %{out_of_service_datestring: same_as_in_service}

      conn = 
        get_via_action(conn, :update_form, repo.jake.id)
        |> follow_form(%{animal: changes})
        |> assert_purpose(form_for_editing_animal())
        |> assert_user_sees(@date_misorder_message)

      inputs =
        form_inputs(conn, :animal)
        |> assert_field(out_of_service_datestring: same_as_in_service)

      service_gap(inputs, 0) |> assert_empty_service_gap_form
      service_gap(inputs, 1) |> assert_unchanged_service_gap_form(repo.sg)
    end

    test "an error only in the existing service gaps", %{conn: conn, repo: repo} do
      changes = %{service_gaps: %{1 => %{in_service_datestring: @iso_date_3}}}

      inputs = 
        get_via_action(conn, :update_form, repo.jake.id)
        |> follow_form(%{animal: changes})
        |> assert_user_sees(@date_misorder_message)
        |> form_inputs(:animal)

      service_gap(inputs, 0) |> assert_empty_service_gap_form

      sg_1_changes = [in_service_datestring: @iso_date_3]
      service_gap(inputs, 1)
      |> assert_unchanged_service_gap_form(repo.sg, except: sg_1_changes)
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

  # ----------------------------------------------------------------------------
  
  defp service_gap(inputs, index), do: subform(inputs, :service_gaps, index)

  defp assert_animal_form_for(inputs, ecto_version) do
    keys = [:name, :lock_version, :in_service_datestring, :out_of_service_datestring]
    expected = VM.Animal.lift(ecto_version, @institution)
    assert_form_matches(inputs, view_model: expected, in: keys)
  end

  # These two functions check the same thing, but they're used in
  # different contexts.
  defp assert_unchanged_service_gap_form(inputs, ecto_version),
    do: assert_service_gap_form_for(inputs, ecto_version)

  defp assert_service_gap_form_for(inputs, ecto_version),
    do: assert_unchanged_service_gap_form(inputs, ecto_version, except: [])

  defp assert_unchanged_service_gap_form(inputs, ecto_version, [except: changes]) do
    keys = [:reason, :in_service_datestring, :out_of_service_datestring, :id, :delete]

    expected =
      VM.ServiceGap.lift(ecto_version, @institution)
      |> struct!(changes)

    assert_form_matches(inputs, view_model: expected, in: keys)
  end
  

  def assert_empty_service_gap_form(inputs) do 
    refute Map.has_key?(inputs, :id)
    refute Map.has_key?(inputs, :delete)
    keys = [:reason, :in_service_datestring, :out_of_service_datestring]
    assert_form_matches(inputs, view_model: %VM.ServiceGap{}, in: keys)
  end
end
