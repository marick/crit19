defmodule CritWeb.Reservations.ReservationController.AfterTheFactTest do
  use CritWeb.ConnCase
  alias CritWeb.Reservations.ReservationController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Ecto.Datespan

  setup :logged_in_as_reservation_manager

  test "the first form", %{conn: conn} do
    get_via_action(conn, :after_the_fact_form_1)
    |> assert_purpose(after_the_fact_pick_species_and_time())
  end

  describe "submitting the first form produces some new HTML" do
    test "success", %{conn: conn} do
      Factory.sql_insert!(:animal,
        [name: "Bossie", span: Datespan.inclusive_up(~D[2019-01-01])],
        @institution)
      
      params = %{species_id: to_string(@bovine_id),
                 date: "2019-01-01",
                 date_showable_date: "January 1, 2019",
                 time_slot_id: "1"}
    
      post_to_action(conn, :after_the_fact_record_1, nested(params))
      |> assert_purpose(after_the_fact_pick_animals())
      |> assert_user_sees("January 1, 2019")
      |> assert_user_sees(@institution_first_time_slot.name)
      |> assert_user_sees("Bossie")
    end
  end


  defp nested(params),
    do: under(:after_the_fact_form, params)
end
