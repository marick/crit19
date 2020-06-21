defmodule CritWeb.Setup.AnimalController.UpdateTest do
  use CritWeb.ConnCase
  use PhoenixIntegration
  alias CritWeb.Setup.AnimalController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Setup.AnimalApi
  alias Crit.Setup.AnimalApi2
  alias Crit.Exemplars
  alias Crit.Extras.{AnimalT, ServiceGapT}
  alias CritWeb.ViewModels.Setup, as: ViewModel
  # alias Crit.Setup.Schemas.ServiceGap
  alias Ecto.Datespan
  import Crit.EctoState
  import Crit.Exemplars.EctoState

  setup :logged_in_as_setup_manager


  describe "the update form" do
    setup do 
      ecto =
        ecto_has_bossie()
        |> service_gap_for("Bossie", starting: @earliest_date)
        |> shorthand()
      [ecto: ecto]
    end
    
    test "unit test", %{conn: conn, ecto: ecto} do
      get_via_action(conn, :update_form, to_string(ecto.bossie.id))
      |> assert_purpose(form_for_editing_animal())
      |> assert_user_sees(["Bossie", @earliest_iso_date])
    end

    test "details about form structure", %{conn: conn, ecto: ecto} do
      bossie = ViewModel.Animal.fetch(:one_for_edit, ecto.bossie.id, @institution)
      bossie_gap = bossie.service_gaps |> singleton_payload

      params = 
        get_via_action(conn, :update_form, to_string(ecto.bossie.id))
        |> fetch_form
        |> animal_params

      params                 |> assert_animal_form(bossie)
      service_gap(params, 0) |> assert_empty_service_gap_form
      service_gap(params, 1) |> assert_service_gap_form(bossie_gap)
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

  describe "update a single animal" do
    setup do 
      ecto =
        empty_ecto()
        |> animal("original_name")
        |> service_gap_for("original_name", reason: "will change")
        |> service_gap_for("original_name", reason: "won't change")
        |> service_gap_for("original_name", reason: "will delete")
        |> shorthand()
      [ecto: ecto]
    end

    test "success", %{conn: conn, ecto: ecto} do
      animal_id = to_string(ecto.original_name.id)

      service_gap_changes = %{
        0 => %{"reason" => "newly added",
               "in_service_datestring" => "2300-01-02",
               "out_of_service_datestring" => "2300-01-03"
              },
        1 => %{reason: "replaces: will change"},
        3 => %{delete: "true"}
      }
      
      get_via_action(conn, :update_form, animal_id)
      |> follow_form(%{animal:
           %{name: "new name!",
             service_gaps: service_gap_changes
           }})
      |> assert_purpose(snippet_to_display_animal())
      # Note that service gaps are not displayed as a part of a snippet
      |> assert_user_sees("new name")
      
      # Check that the changes propagate
      animal = AnimalApi2.one_by_id(animal_id, @institution, preload: [:service_gaps])
      assert_field(animal, name: "new name!")

      [changed, _unchanged, added] =
        animal.service_gaps |> Enum.sort_by(fn gap -> gap.id end)

      assert_field(changed, reason: "replaces: will change")
      assert_fields(added,
        reason: "newly added",
        span: Datespan.customary(~D[2300-01-02], ~D[2300-01-03]))
    end

    @tag :skip
    test "a *blank* service gap form is ignored",
      %{conn: conn, animal_id: animal_id} do
      # It's not treated as an attempt to create a new service gap
      params =
        animal_id
        |> AnimalApi.updatable!(@institution)
        |> AnimalT.unchanged_params
        # change a field in the animal itself so that we can see something happen
        |> Map.put("name", "new name")

      post_to_action(conn, [:update, to_string(animal_id)], under(:animal_old, params))
      # There was not a failure (which renders a different snippet)
      |> assert_purpose(snippet_to_display_animal())
      
      # Check that the changes did actually happen
      animal = AnimalApi.updatable!(animal_id, @institution)
      assert_field(animal, name: "new name")

      # The blank service gap parameter does not appear in result.
      assert map_size(params["service_gaps"]) == 3
      assert length(animal.service_gaps) == 2
    end

    @tag :skip
    test "update failures produce appropriate annotations", 
    %{conn: conn, animal_id: animal_id} do

      Exemplars.Available.animal_id(name: "name clash")

      params =
        animal_id
        |> AnimalApi.updatable!(@institution)
        |> AnimalT.unchanged_params
        # Dates are in wrong order
        |> put_in(["in_service_datestring"], @iso_date_2)
        |> put_in(["out_of_service_datestring"], @iso_date_1)
        # ... and there's an error in a service gap change.
        |> put_in(["service_gaps", "0", "out_of_service_datestring"], "nver")

      post_to_action(conn, [:update, to_string(animal_id)], under(:animal_old, params))
      |> assert_purpose(form_for_editing_animal())
      |> assert_user_sees(@date_misorder_message)
      |> assert_user_sees("is invalid")
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
end
