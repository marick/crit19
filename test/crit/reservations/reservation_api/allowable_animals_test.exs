defmodule Crit.Reservations.ReservationApi.AllowableAnimalsTest do
  use Crit.DataCase
  alias Ecto.Datespan
  alias Crit.Reservations.ReservationApi

  describe "`available_after_the_fact`" do
    setup do
      to_be_found = [name: "bovine", species_id: @bovine_id,
                     span: Datespan.customary(@date_2, @date_8)
                    ]

      to_be_ordered_second = Keyword.replace!(to_be_found, :name, "later")
      to_be_skipped = [species_id: @equine_id,
                       span: Datespan.customary(@date_2, @date_8)]

      # Order is significant because the default ordering is by id.
      Factory.sql_insert!(:animal, to_be_ordered_second, @institution)
      %{id: to_be_found_id} = Factory.sql_insert!(:animal, to_be_found, @institution)
      Factory.sql_insert!(:animal, to_be_skipped, @institution)

      [to_be_found_id: to_be_found_id]
    end
    
    test "the species matters" do
      assert_after_the_fact(%{species_id: @bovine_id, date: @date_2})
    end

    test "the date matters" do 
      assert_after_the_fact(%{species_id: @bovine_id, date: @date_2})
      assert_after_the_fact(%{species_id: @bovine_id, date: @date_7})
      
      refute_after_the_fact(%{species_id: @bovine_id, date: @date_1})
      refute_after_the_fact(%{species_id: @bovine_id, date: @date_8})
    end

    test "service gaps do NOT matter", %{to_be_found_id: animal_id} do
      Factory.sql_insert!(:service_gap,
        [animal_id: animal_id,
         span: Datespan.customary(@date_2, @date_8)],
        @institution)

      assert_after_the_fact(%{species_id: @bovine_id, date: @date_2})
      assert_after_the_fact(%{species_id: @bovine_id, date: @date_7})
      
      refute_after_the_fact(%{species_id: @bovine_id, date: @date_1})
      refute_after_the_fact(%{species_id: @bovine_id, date: @date_8})
    end

    test "animal being in use does not matter" do
    end

    def assert_after_the_fact(map) do 
      actual = ReservationApi.allowable_animals_after_the_fact(map, @institution)
      assert [%{name: "bovine"}, %{name: "later"}] = actual
    end

    def refute_after_the_fact(map) do 
      actual = ReservationApi.allowable_animals_after_the_fact(map, @institution)
      assert [] = actual
    end
  end
end
