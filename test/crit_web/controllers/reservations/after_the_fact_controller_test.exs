defmodule CritWeb.Reservations.AfterTheFactControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.Reservations.AfterTheFactController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Ecto.Datespan
  alias Crit.MultiStepCache, as: Cache

  setup :logged_in_as_reservation_manager


  @transaction_key Cache.new_key()
  @iso_date "2019-01-01"
  @date ~D[2019-01-01]
  @human_date "January 1, 2019"


  setup do
    given Cache.new_key, [], do: @transaction_key
    :ok
  end
    

  test "getting the first form", %{conn: conn} do
    get_via_action(conn, :start)
    |> assert_purpose(after_the_fact_pick_species_and_time())
  end

  describe "submitting the first form produces some new HTML" do
    test "success", %{conn: conn} do
      Factory.sql_insert!(:animal,
        [name: "Bossie", species_id: @bovine_id,
         span: Datespan.inclusive_up(@date)],
        @institution)

      params = %{species_id: to_string(@bovine_id),
                 date: @iso_date,
                 date_showable_date: @human_date,
                 time_slot_id: "1"}

      post_to_action(conn, :put_species_and_time, under(:start_data, params))
      |> assert_purpose(after_the_fact_pick_animals())
      |> assert_user_sees("January 1, 2019")
      |> assert_user_sees(@institution_first_time_slot.name)
      |> assert_user_sees("Bossie")
      |> assert_user_sees(@transaction_key)

      Cache.get(@transaction_key)
      |> assert_fields(species_id: @bovine_id,
                       date: @date,
                       time_slot_id: 1)
    end
  end
end
