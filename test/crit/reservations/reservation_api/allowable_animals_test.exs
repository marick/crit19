defmodule Crit.Reservations.ReservationApi.AllowableAnimalsTest do
  use Crit.DataCase
  alias Ecto.{Datespan,Timespan}
  alias Crit.Reservations.ReservationApi
  alias Crit.Exemplars.ReservationFocused

  
  
  describe "`available_after_the_fact`" do

    @to_be_found_name "some bovine"
    @sorts_second "zzz later"
    
    setup do
      to_be_found = [name: @to_be_found_name, species_id: @bovine_id,
                     span: Datespan.customary(@date_2, @date_8)
                    ]

      to_be_ordered_second = Keyword.replace!(to_be_found, :name, @sorts_second)
      to_be_skipped = [species_id: @equine_id,
                       span: Datespan.customary(@date_2, @date_8)]

      # Order is significant because the default ordering is by id.
      Factory.sql_insert!(:animal, to_be_ordered_second, @institution)
      %{id: to_be_found_id} = Factory.sql_insert!(:animal, to_be_found, @institution)
      Factory.sql_insert!(:animal, to_be_skipped, @institution)

      [to_be_found_id: to_be_found_id]
    end
    
    test "the species matters" do
      assert_after_the_fact(%{date: @date_2})
    end

    test "the date matters" do 
      assert_after_the_fact(%{date: @date_2})
      assert_after_the_fact(%{date: @date_7})
      
      refute_after_the_fact(%{date: @date_1})
      refute_after_the_fact(%{date: @date_8})
    end

    test "service gaps do NOT matter", %{to_be_found_id: animal_id} do
      Factory.sql_insert!(:service_gap,
        [animal_id: animal_id,
         span: Datespan.customary(@date_2, @date_8)],
        @institution)

      assert_after_the_fact(%{date: @date_2})
      assert_after_the_fact(%{date: @date_7})
      
      refute_after_the_fact(%{date: @date_1})
      refute_after_the_fact(%{date: @date_8})
    end

    test "animal being in use does NOT matter" do
      ReservationFocused.reserved!(@bovine_id,
        [@to_be_found_name], ["ignored"],
        date: @date_4, span: only_timespan())

      assert_after_the_fact(%{date: @date_4})
    end
  end

  defp only_timespan,
    do: Timespan.from_date_time_and_duration(@date_4, ~T[08:00:00.000], 60)        
  
  defp desired(partial_map),
    do: Enum.into(partial_map, %{species_id: @bovine_id, span: only_timespan()})

  defp assert_after_the_fact(partial_map) do
    actual =
      desired(partial_map)
      |> ReservationApi.allowable_animals_after_the_fact(@institution)
    
    assert [%{name: @to_be_found_name}, %{name: @sorts_second}] = actual
  end
  
  defp refute_after_the_fact(partial_map) do 
    actual =
      desired(partial_map)
      |> ReservationApi.allowable_animals_after_the_fact(@institution)
    assert [] = actual
  end
end
