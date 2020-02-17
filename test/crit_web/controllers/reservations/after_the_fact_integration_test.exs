defmodule CritWeb.Reservations.AfterTheFactIntegrationTest do
  use CritWeb.IntegrationCase
  alias CritWeb.Reservations.AfterTheFactController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Ecto.Datespan
  alias Crit.State.UserTask
#  alias Crit.Setup.InstitutionApi
#  alias Crit.Reservations.Schemas.Reservation
  #  alias Crit.Sql

  setup :logged_in_as_reservation_manager

  @task_id UserTask.new_key()
  @iso_date "2019-01-01"
  @date ~D[2019-01-01]
  @human_date "January 1, 2019"
  @time_slot_id 1

  setup do
    given UserTask.new_key, [], do: @task_id
    UserTask.delete(@task_id)
    bossie = Factory.sql_insert!(:animal,
      [name: "Bossie", species_id: @bovine_id,
       span: Datespan.inclusive_up(@date)],
      @institution)

    unchecked = Factory.sql_insert!(:animal,
      [name: "Bossie2", species_id: @bovine_id,
       span: Datespan.inclusive_up(@date)],
      @institution)

    procedure = Factory.sql_insert!(:procedure,
      [name: "only procedure", species_id: @bovine_id],
      @institution)

    [bossie: bossie, procedure: procedure, unchecked: unchecked]
  end


  test "after-the-fact reservation workflow",
    %{conn: conn, bossie: bossie, unchecked: _unchecked, procedure: _procedure} do
    # ----------------------------------------------------------------------------
    get_via_action(conn, :start)                             # Start
    |> assert_purpose(after_the_fact_pick_species_and_time())

    # ----------------------------------------------------------------------------
    |> follow_form(%{species_and_time:                       # Background info
         %{species_id: @bovine_id,
           date: @iso_date,
           date_showable_date: @human_date,
           time_slot_id: @time_slot_id}})
    |> assert_purpose(after_the_fact_pick_animals())
    |> assert_user_sees_time_header
    |> assert_animal_choice("Bossie")
    # ----------------------------------------------------------------------------

    |> follow_form(%{animals:                               # Pick animals
          %{chosen_animal_ids: [bossie.id]}})
    |> assert_purpose(after_the_fact_pick_procedures())
    |> assert_user_sees(@task_id)
    |> assert_user_sees_time_header
    |> assert_user_sees_animal_header
    |> assert_procedure_choice("only procedure")
  end
  
  # ----------------------------------------------------------------------------


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

  defp assert_user_sees_animal_header(conn) do
    conn
    |> assert_user_sees("Bossie")
  end    
  
  defp assert_user_sees_time_header(conn) do
    assert_response(conn,
      html: @task_id,
      html: "January 1, 2019",
      html: @institution_first_time_slot.name)
  end
    
end
