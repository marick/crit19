defmodule CritWeb.Reservations.AfterTheFactIntegrationTest do
  use CritWeb.IntegrationCase
  alias CritWeb.Reservations.AfterTheFactController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.State.UserTask
  alias Crit.Exemplars.Available
  alias Crit.Reservations.ReservationApi
  alias Crit.Setup.InstitutionApi
  alias Ecto.Timespan

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

    [only] = ReservationApi.reservations_on_date(@date, @institution)
    assert_correct_result(only, picked_animal, picked_procedure)
  end


  defp assert_correct_result(reservation, picked_animal, picked_procedure) do 
    assert_fields(reservation,
      species_id: @bovine_id,
      date: @date,
      span: expected_span(),
      timeslot_id: @timeslot_id,
      animal_pairs: [{picked_animal.name, picked_animal.id}],
      procedure_pairs: [{picked_procedure.name, picked_procedure.id}]
    )
  end

  # A little paranoia here.
  defp expected_span do 
    one_way =
      InstitutionApi.timespan(@date, @timeslot_id, @institution)
    another =
      Timespan.from_date_time_and_duration(@date, ~T[08:00:00], 4 * 60)
    assert one_way == another
    
    assert_fields(InstitutionApi.timeslot_by_id(@timeslot_id, @institution),
      start: ~T[08:00:00], duration: 4 * 60)

    one_way
  end
end
