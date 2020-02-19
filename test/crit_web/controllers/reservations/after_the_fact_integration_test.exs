defmodule CritWeb.Reservations.AfterTheFactIntegrationTest do
  use CritWeb.IntegrationCase
  alias CritWeb.Reservations.AfterTheFactController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.State.UserTask
  alias Crit.Exemplars.Available
#  alias Crit.Reservations.Schemas.Reservation
#  alias Crit.Sql

  setup :logged_in_as_reservation_manager

  @task_id UserTask.new_id()
  @iso_date "2019-01-01"
  @date ~D[2019-01-01]
  @human_date "January 1, 2019"
  @timeslot_id 1

  setup do
    given UserTask.new_id, [], do: @task_id
    UserTask.delete(@task_id)

    picked_animal = Available.bovine("Bossie", @date)
    _not_picked = Available.bovine("Unchecked", @date)
    picked_procedure = Available.bovine_procedure("only procedure")
    [picked_animal: picked_animal, picked_procedure: picked_procedure]
  end


  test "after-the-fact reservation workflow",
    %{conn: conn, picked_animal: picked_animal,
      picked_procedure: picked_procedure} do 
    # ----------------------------------------------------------------------------
    get_via_action(conn, :start)                             # Start
    |> assert_purpose(after_the_fact_pick_species_and_time())
    # ----------------------------------------------------------------------------
    |> follow_form(%{species_and_time:                       # Background info
         %{species_id: @bovine_id,
           date: @iso_date,
           date_showable_date: @human_date,
           timeslot_id: @timeslot_id}})
    # ----------------------------------------------------------------------------
    |> follow_form(%{animals:                               # Pick animals
          %{chosen_animal_ids: [picked_animal.id]}})

    |> follow_form(%{procedures:                               # Pick animals
          %{chosen_procedure_ids: [picked_procedure.id]}})

    IO.puts "check created reservation details"
    # IO.inspect Sql.all(Reservation, @institution)
    
  end
  
  # ----------------------------------------------------------------------------
end
