defmodule CritWeb.Reservations.ByAnimalIntegrationTest do
  use CritWeb.IntegrationCase
  alias CritWeb.Reservations.ReservationController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  # alias Crit.State.UserTask
  # alias Crit.Exemplars.Available
  # alias Crit.Reservations.ReservationApi
  # alias Crit.Setup.InstitutionApi
  # alias Ecto.Timespan
  alias Crit.Exemplars.ReservationFocused

  setup :logged_in_as_reservation_manager

  setup do
    ReservationFocused.reserved!(@bovine_id,
      ["Jeff", "bossie"], ["procedure 1", "procedure 2"])
    :ok
  end


  test "by-animal workflow", %{conn: conn} do 
    # ----------------------------------------------------------------------------
    get_via_action(conn, :by_animal_form)
    |> assert_purpose(reservation_by_animal())
    # ----------------------------------------------------------------------------
    # |> follow_form(%{animal: %{date: @iso_date}})
  end
end
