defmodule Integration.Reservations.AfterTheFactTest do
  use CritWeb.IntegrationCase
  alias CritWeb.Reservations.AfterTheFactController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Servers.UserTask
  alias Crit.Reservations.ReservationApi
  alias Crit.Setup.InstitutionApi
  alias Ecto.Timespan
  import Crit.RepoState
  use FlowAssertions
  alias Crit.Schemas.Reservation

  setup :logged_in_as_reservation_manager

  @task_id UserTask.new_id()
  @iso_date "2019-01-01"
  @date ~D[2019-01-01]
  @human_date "January 1, 2019"
  @timeslot_id 1

  setup do
    given UserTask.new_id, [], do: @task_id
    UserTask.delete(@task_id)

    repo =
      empty_repo(@bovine_id)
      |> animal("picked_animal", available: @date)
      |> animal("not picked", available: @date)
      |> procedure("picked_procedure")
    
    [picked_animal: repo.picked_animal, picked_procedure: repo.picked_procedure]
  end


  test "after-the-fact reservation workflow",
    %{conn: conn, picked_animal: picked_animal, picked_procedure: picked_procedure} do
    # ----------------------------------------------------------------------------
    get_via_action(conn, :start)                             # Start
    # ----------------------------------------------------------------------------
    |> follow_form(%{context:                                # Background info
         %{species_id: @bovine_id,
           date: @iso_date,
           date_showable_date: @human_date,
           responsible_person: "dster",
           timeslot_id: @timeslot_id}})
    # ----------------------------------------------------------------------------
    |> follow_form(%{animals:                               # Pick animals
          %{chosen_animal_ids: [picked_animal.id]}})
    # ----------------------------------------------------------------------------
    |> follow_form(%{procedures:                            # Pick procedures
          %{chosen_procedure_ids: [picked_procedure.id]}})
    # ----------------------------------------------------------------------------

    ReservationApi.on_date(@date, @institution)
    |> singleton_content(Reservation)
    |> assert_correct_result(picked_animal, picked_procedure)
  end


  defp assert_correct_result(reservation, picked_animal, picked_procedure) do 
    assert_fields(reservation,
      species_id: @bovine_id,
      date: @date,
      span: expected_span(),
      responsible_person: "dster",
      timeslot_id: @timeslot_id
    )

    assert {[animal], [procedure]} =
      ReservationApi.all_used(reservation.id, @institution)
    assert animal.id == picked_animal.id
    assert procedure.id == picked_procedure.id
  end

  # A little paranoia here.
  defp expected_span do 
    one_way =
      InstitutionApi.timespan(@date, @timeslot_id, @institution)
    another =
      Timespan.from_date_time_and_duration(@date, ~T[08:00:00], 4 * 60)
    assert one_way == another
    one_way
  end
end
