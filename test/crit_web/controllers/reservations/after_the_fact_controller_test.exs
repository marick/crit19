defmodule CritWeb.Reservations.AfterTheFactControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.Reservations.AfterTheFactController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.State.UserTask
  alias CritWeb.Reservations.AfterTheFactStructs.State
  alias Crit.Setup.InstitutionApi
  alias Crit.Reservations.Schemas.Reservation
  alias Crit.Sql
  alias Crit.Exemplars.Available

  setup :logged_in_as_reservation_manager


  @task_id UserTask.new_id()
  @iso_date "2019-01-01"
  @date ~D[2019-01-01]
  @human_date "January 1, 2019"
  @time_slot_id 1


  setup do
    given UserTask.new_id, [], do: @task_id
    UserTask.delete(@task_id)
    bossie = Available.bovine("Bossie", @date)
    procedure = Available.bovine_procedure("only procedure")
    [bossie: bossie, procedure: procedure]
  end

  test "getting the first form", %{conn: conn} do
    get_via_action(conn, :start)
    |> assert_purpose(after_the_fact_pick_species_and_time())
  end

  describe "submitting the date-and-species form produces some new HTML" do
    test "success", %{conn: conn} do
      params = %{species_id: to_string(@bovine_id),
                 date: @iso_date,
                 date_showable_date: @human_date,
                 institution: @institution,
                 time_slot_id: to_string(@time_slot_id)}

      post_to_action(conn, :put_species_and_time, under(:species_and_time, params))
      |> assert_purpose(after_the_fact_pick_animals())
      |> assert_user_sees(@task_id)
      |> assert_user_sees("January 1, 2019")
      |> assert_user_sees(@institution_first_time_slot.name)
      |> assert_animal_choice("Bossie")

      UserTask.get(@task_id)
      |> assert_fields(
           species_id: @bovine_id,
           date: @date,
           time_slot_id: @time_slot_id,
           span: InstitutionApi.timespan(@date, @time_slot_id, @institution),
           institution: @institution,
           task_id: @task_id)
    end
  end

  describe "submitting animal ids prompts a call for procedure ids" do
    test "success", %{conn: conn, bossie: bossie} do
      params = %{task_id: @task_id,
                 chosen_animal_ids: [to_string(bossie.id)],
                 institution: @institution}

      UserTask.start(%State{
            species_id: @bovine_id,
            species_and_time_header: "TIME HEADER"})

      post_to_action(conn, :put_animals, under(:animals, params))
      |> assert_purpose(after_the_fact_pick_procedures())
      |> assert_user_sees(@task_id)
      |> assert_user_sees("TIME HEADER")
      |> assert_animal_header
      |> assert_procedure_choice("only procedure")

      UserTask.get(@task_id)
      |> assert_fields(chosen_animal_ids: [bossie.id])
    end
  end

  describe "finishing up" do
    test "success", %{conn: conn, bossie: bossie, procedure: procedure} do
      params = %{task_id: @task_id,
                 chosen_procedure_ids: [to_string(procedure.id)],
                 institution: @institution}

      UserTask.start(%State{
            species_id: @bovine_id,
            span: InstitutionApi.timespan(@date, @time_slot_id, @institution),
            chosen_animal_ids: [bossie.id]})


      post_to_action(conn, :put_procedures, under(:procedures, params))
      # IO.inspect Sql.all(Reservation, @institution)
    end
  end


  defp assert_animal_choice(conn, who) do
    conn
    |> assert_user_sees(who)
    |> assert_user_sees("chosen_animal_ids")
  end

  defp assert_procedure_choice(conn, what) do
    conn
    |> assert_user_sees(what)
    |> assert_user_sees("chosen_procedure_ids")
  end

  defp assert_animal_header(conn) do
    conn
    |> assert_user_sees("Bossie")
  end    
  
end
