defmodule CritWeb.Reservations.AfterTheFactIntegrationTest do
  use CritWeb.IntegrationCase
  alias CritWeb.Reservations.AfterTheFactController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Ecto.Datespan
  alias Crit.MultiStepCache, as: Cache
#  alias CritWeb.Reservations.AfterTheFactData, as: Data
  alias Crit.Setup.InstitutionApi
#  alias Crit.Reservations.Schemas.Reservation
  #  alias Crit.Sql

  setup :logged_in_as_reservation_manager

  @transaction_key Cache.new_key()
  @iso_date "2019-01-01"
  @date ~D[2019-01-01]
  @human_date "January 1, 2019"
  @time_slot_id 1

  setup do
    given Cache.new_key, [], do: @transaction_key
    Cache.delete(@transaction_key)
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


  test "getting the first form",
    %{conn: conn, bossie: bossie, unchecked: unchecked, procedure: _procedure} do
     has_start_form = 
      get_via_action(conn, :start)
      |> assert_purpose(after_the_fact_pick_species_and_time())

     # ----------------------------------------------------------------------------
     has_animal_form = 
       follow_form(has_start_form,
         %{ species_and_time:
            %{species_id: to_string(@bovine_id),
              date: @iso_date,
              date_showable_date: @human_date,
              time_slot_id: to_string(@time_slot_id)
            }})
       |> assert_purpose(after_the_fact_pick_animals())
       |> assert_user_sees_time_header
       |> assert_animal_choice("Bossie")

      Cache.get(@transaction_key)
      |> assert_fields(
           species_id: @bovine_id,
           date: @date,
           time_slot_id: @time_slot_id,
           span: InstitutionApi.timespan(@date, @time_slot_id, @institution),
           institution: @institution)
      # ----------------------------------------------------------------------------

      

      _has_procedure_form =
        follow_form(has_animal_form,
          %{animals:
            %{chosen_animal_ids: [bossie.id]}})
      |> assert_purpose(after_the_fact_pick_procedures())
      |> assert_user_sees(@transaction_key)
      |> assert_user_sees_time_header
      |> assert_user_sees_animal_header
      |> assert_procedure_choice("only procedure")
  end

    


  # defp check_and_follow_form(conn, top_level, second_level, checked) do
  #  should_be_true =
  #    Enum.map(checked, fn key -> to_string(key) |> String.to_atom end)

  #  all_keys =
  #    get_in(fetch_form(conn), [:inputs, top_level, second_level]) |> Map.keys


  #  second_level =
     
  #  pair = fn key ->
  #    value = Enum.member?(should_be_true, key) |> to_string
  #    {key, value}
  #  end

  #  %{field => Enum.map(should_be_true, pair) |> Map.new}
  # end    
  

 # defp checked_checkbox(conn, field, key), do: checked_checkboxes(conn, field, [key])

 # defp checked_checkboxes(conn, field, keys) do

 #   should_be_true =
 #     Enum.map(keys, fn key -> to_string(key) |> String.to_atom end)

 #   all_keys =
 #     get_in(fetch_form(conn), [:inputs, :animals, field]) |> Map.keys

 #   pair = fn key ->
 #     value = Enum.member?(should_be_true, key) |> to_string
 #     {key, value}
 #   end

 #   %{field => Enum.map(should_be_true, pair) |> Map.new}
 # end

 # defp checked_checkboxes_true_and_false(conn, field, keys) do
 #   should_be_true =
 #     Enum.map(keys, fn key -> to_string(key) |> String.to_atom end)

 #   all_keys =
 #     get_in(fetch_form(conn), [:inputs, :animals, field]) |> Map.keys

 #   pair = fn key ->
 #     value = Enum.member?(should_be_true, key) |> to_string
 #     {key, value}
 #   end

 #   %{field => Enum.map(all_keys, pair) |> Map.new}
 # end


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
      html: @transaction_key,
      html: "January 1, 2019",
      html: @institution_first_time_slot.name)
  end
    
end
