defmodule CritWeb.Reservations.AfterTheFactControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.Reservations.AfterTheFactController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  import Crit.RepoState
  alias CritWeb.Reservations.ReservationController
  alias Crit.State.UserTask
  alias CritBiz.ViewModels.Reservation.AfterTheFact.TaskMemory
  alias Crit.Setup.{InstitutionApi}
  alias Crit.Reservations.ReservationApi
  alias Ecto.Datespan
  use FlowAssertions
  use FlowAssertions.NoValueA, no_value: :nothing
  

  setup :logged_in_as_reservation_manager

  @task_id UserTask.new_id()
  @iso_date "2019-01-01"
  @date ~D[2019-01-01]
  @human_date "January 1, 2019"
  @timeslot_id 1
  @span InstitutionApi.timespan(@date, @timeslot_id, @institution)
  
  setup do
    given UserTask.new_id, [], do: @task_id
    UserTask.delete(@task_id)

    repo = 
      empty_repo(@bovine_id)
      |> animal("Bossie", available: @date)
      |> procedure("only_procedure")
    
    [bossie: repo.bossie, procedure: repo.only_procedure]
  end

  test "getting the first form", %{conn: conn} do
    get_via_action(conn, :start)
    |> assert_purpose(after_the_fact_pick_non_use_values())

    UserTask.get(@task_id)
    |> assert_field(task_id: @task_id)
  end

  describe "submitting the date, species, etc. form produces some new HTML" do
    setup do
      params = %{species_id: to_string(@bovine_id),
                 date: @iso_date,
                 date_showable_date: @human_date,
                 timeslot_id: to_string(@timeslot_id),
                 responsible_person: "dster",
                 task_id: @task_id}
      [params: params]
    end
    
    test "success", %{conn: conn, params: params} do
      UserTask.start(%TaskMemory{task_id: @task_id})

      post_to_action(conn, :put_non_use_values, under(:non_use_values, params))
      |> assert_purpose(after_the_fact_pick_animals())

      expected_span = InstitutionApi.timespan(@date, @timeslot_id, @institution)
      UserTask.get(@task_id)
      |> assert_field(span: expected_span,
                      responsible_person: "dster")
      |> refute_no_value([:species_id, :timeslot_id, :date_showable_date])
    end

    test "task_id has expired", %{conn: conn, params: params} do
      UserTask.delete(@task_id)
      post_to_action(conn, :put_animals, under(:animals, params))
      |> assert_redirected_to(UnderTest.path(:start))
      |> assert_error_flash_has(UserTask.expiry_message())
    end

    test "for some reason, browsers don't obey the calendar's `required` attr",
      %{conn: conn, params: original} do

      params = %{original | date: "", date_showable_date: ""}
      UserTask.start(%TaskMemory{task_id: @task_id})

      post_to_action(conn, :put_non_use_values, under(:non_use_values, params))
      |> assert_purpose(after_the_fact_pick_non_use_values())
      |> assert_user_sees("be blank")

      UserTask.get(@task_id)
      |> assert_field(task_id: @task_id)
    end
  end

  describe "submitting animal ids prompts a call for procedure ids" do
    setup do
      UserTask.start(%TaskMemory{
            species_id: @bovine_id,
            date: @date,
            span: @span,
            responsible_person: "dster",
            task_header: "HEADER"})
      :ok
    end
       
    test "success", %{conn: conn, bossie: bossie} do
      params = %{task_id: @task_id,
                 chosen_animal_ids: [to_string(bossie.id)]}

      post_to_action(conn, :put_animals, under(:animals, params))
      |> assert_purpose(after_the_fact_pick_procedures())

      UserTask.get(@task_id)
      |> assert_field(chosen_animal_ids: [bossie.id])
    end

    test "you must select at least one", %{conn: conn} do
      params = %{task_id: @task_id}
      post_to_action(conn, :put_animals, under(:animals, params))
      |> assert_purpose(after_the_fact_pick_animals())
      |> assert_user_sees("You have to select at least one animal")
    end

    test "the task id has expired", %{conn: conn} do
      # Note that expiry takes precedence over no animals having been chosen.
      params = %{task_id: @task_id}
      UserTask.delete(@task_id)
      post_to_action(conn, :put_animals, under(:animals, params))
      |> assert_redirected_to(UnderTest.path(:start))
      |> assert_error_flash_has(UserTask.expiry_message())
    end
  end

  describe "finishing up" do
    setup %{bossie: bossie} do
      state_copy =
        UserTask.start(%TaskMemory{
            species_id: @bovine_id,
            date: @date,
            span: @span,
            timeslot_id: @timeslot_id,
            task_header: "HEADER",
            responsible_person: "dster",
            chosen_animal_ids: [bossie.id]})
      [state_copy: state_copy]
    end

    test "success", %{conn: conn, procedure: procedure} do
      params = %{task_id: @task_id,
                 chosen_procedure_ids: [to_string(procedure.id)]}

      conn = post_to_action(conn, :put_procedures, under(:procedures, params))

      [only] = ReservationApi.on_date(@date, @institution)
      assert_fields(only, date: @date, timeslot_id: @timeslot_id)
      assert_redirected_to(conn, ReservationController.path(:show, only.id))
      refute UserTask.get(@task_id)
      assert_info_flash_has(conn, "reservation was created")
    end

    test "you must select at least one procedure", %{conn: conn} do
      params = %{task_id: @task_id}
      post_to_action(conn, :put_procedures, under(:procedures, params))
      |> assert_purpose(after_the_fact_pick_procedures())
      |> assert_user_sees("You have to select at least one procedure")
    end

    test "make sure unchosen procedures are not included.",
      %{conn: conn, procedure: procedure} do
      params = %{task_id: @task_id,
                 chosen_procedure_ids: [to_string(procedure.id)]}

      Factory.sql_insert!(:procedure, name: "NOT_INCLUDED")

      post_to_action(conn, :put_procedures, under(:procedures, params))


      [only_reservation] = ReservationApi.on_date(@date, @institution)
      {[_only_use], _} = ReservationApi.all_used(only_reservation.id, @institution)
    end

    test "the task id has expired", %{conn: conn, procedure: procedure} do
      params = %{task_id: @task_id,
                 chosen_procedure_ids: [to_string(procedure.id)]}
      UserTask.delete(@task_id)
      post_to_action(conn, :put_procedures, under(:procedures, params))
      |> assert_redirected_to(UnderTest.path(:start))
      |> assert_error_flash_has(UserTask.expiry_message())
    end

    test "if the animal was already reserved, that's noted",
      %{conn: conn, state_copy: again, procedure: procedure, bossie: bossie} do
      params = %{task_id: @task_id,
                 chosen_procedure_ids: [procedure.id]}

      conn = post_to_action(conn, :put_procedures, under(:procedures, params))

      UserTask.start(again)

      conn = post_to_action(conn, :put_procedures, under(:procedures, params))
      # After the fact, the duplicate reservation is made.
      [_first, _second] = ReservationApi.on_date(@date, @institution)
      
      conn
      |> assert_info_flash_has("created despite")
      |> assert_info_flash_has(bossie.name)
    end

    test "if the animal had a service gap, that's noted",
      %{conn: conn, bossie: bossie, procedure: procedure} do
      params = %{task_id: @task_id,
                 chosen_procedure_ids: [to_string(procedure.id)]}

      Factory.sql_insert!(:service_gap,
        [animal_id: bossie.id,
         span: Datespan.customary(@date, Date.add(@date, 1))],
      @institution)

      conn = post_to_action(conn, :put_procedures, under(:procedures, params))

      conn
      |> assert_info_flash_has("created despite")
      |> assert_info_flash_has(bossie.name)
    end
    
  end
end
