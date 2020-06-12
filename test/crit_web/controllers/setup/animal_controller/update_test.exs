defmodule CritWeb.Setup.AnimalController.UpdateTest do
  use CritWeb.ConnCase
  alias CritWeb.Setup.AnimalController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Setup.AnimalApi
  alias Crit.Exemplars
  alias Crit.Extras.{AnimalT, ServiceGapT}
  alias Ecto.Datespan
  import Crit.Exemplars.Background

  setup :logged_in_as_setup_manager


  describe "the update form" do
    setup do 
      b =
        background()
        |> animal("Bossie")
        |> service_gap_for("Bossie", starting: @earliest_date)
        |> shorthand()
      [background: b]
    end
    
    test "unit test", %{conn: conn, background: b} do
      get_via_action(conn, :update_form, to_string(b.bossie.id))
      |> assert_purpose(form_for_editing_animal())
      |> assert_user_sees(["Bossie", @earliest_iso_date])
    end
  end

  describe "update a single animal" do
    setup do
      id = Exemplars.Available.animal_id(name: "original name")
      _will_changed = Factory.sql_insert!(:service_gap, [animal_id: id], @institution)
      _will_vanish = Factory.sql_insert!(:service_gap, [animal_id: id], @institution)
      
      [animal_id: id]
    end

    @tag :skip
    test "success", %{conn: conn, animal_id: animal_id} do
      new_service_gap = %{"in_service_datestring" => "2300-01-02",
                          "out_of_service_datestring" => "2300-01-03",
                          "reason" => "newly added"
                         }
      
      params =
        animal_id
        |> AnimalApi.updatable!(@institution)
        |> AnimalT.unchanged_params
        # change a field in the animal itself
        |> Map.put("name", "new name")
        # add a service gap
        |> put_in(["service_gaps", "0"], new_service_gap     )
        # change a field in one of the service gaps
        |> put_in(["service_gaps", "1", "reason"], "fixored reason")
        # delete the other 
        |> put_in(["service_gaps", "2", "delete"], "true")

      post_to_action(conn, [:update, to_string(animal_id)], under(:animal_old, params))
      |> assert_purpose(snippet_to_display_animal())
      # Note that service gaps are not displayed as a part of a snippet
      |> assert_user_sees("new name")
      
      # Check that the changes propagate
      animal = AnimalApi.updatable!(animal_id, @institution)
      assert_field(animal, name: "new name")

      [changed, added] =
        animal.service_gaps |> Enum.sort_by(fn gap -> gap.id end)

      assert_field(changed,
        reason: "fixored reason")
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
