defmodule CritWeb.Reservations.AfterTheFactControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.Reservations.AfterTheFactController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Ecto.Datespan
  alias Crit.MultiStepCache, as: Cache
  alias CritWeb.Reservations.AfterTheFact.StartData

  setup :logged_in_as_reservation_manager


  @transaction_key Cache.new_key()
  @iso_date "2019-01-01"
  @date ~D[2019-01-01]
  @human_date "January 1, 2019"


  setup do
    given Cache.new_key, [], do: @transaction_key
    Cache.delete(@transaction_key)
    bossie = Factory.sql_insert!(:animal,
      [name: "Bossie", species_id: @bovine_id,
       span: Datespan.inclusive_up(@date)],
      @institution)
    [bossie: bossie]
  end

  test "getting the first form", %{conn: conn} do
    get_via_action(conn, :start)
    |> assert_purpose(after_the_fact_pick_species_and_time())
  end

  describe "submitting the first form produces some new HTML" do
    test "success", %{conn: conn, bossie: bossie} do
      params = %{species_id: to_string(@bovine_id),
                 date: @iso_date,
                 date_showable_date: @human_date,
                 time_slot_id: "1"}

      post_to_action(conn, :put_species_and_time, under(:start_data, params))
      |> assert_purpose(after_the_fact_pick_animals())
      |> assert_common_to_two_steps()

      Cache.get(@transaction_key)
      |> assert_fields(species_id: @bovine_id,
                       date: @date,
                       time_slot_id: 1,
                       animal_names: %{bossie.id => bossie.name})
    end
  end


  describe "submitting animal ids prompts a call for procedure ids" do
    test "success", %{conn: conn} do
      params = %{transaction_key: @transaction_key,
                 chosen_animal_ids: %{to_string(@bovine_id) => "true"}}

      Cache.put_first(%StartData{date_showable_date: "January 1, 2019",
                                 time_slot_name: @institution_first_time_slot.name,
                                 species_name: @bovine})
      Cache.add(@transaction_key, :animal_names, %{@bovine_id => "Bossie"})

      post_to_action(conn, :put_animals, under(:animals, params))
      |> assert_purpose(after_the_fact_pick_procedures())
      |> assert_common_to_two_steps()
    end
  end


  defp assert_common_to_two_steps(conn) do
    conn
    |> assert_user_sees("January 1, 2019")
    |> assert_user_sees(@institution_first_time_slot.name)
    |> assert_user_sees("Bossie")
    |> assert_user_sees(@transaction_key)
  end
  
end
