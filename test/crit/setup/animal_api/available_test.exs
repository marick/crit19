defmodule Crit.Setup.AnimalApi.AvailableTest do
  use Crit.DataCase
  alias Ecto.Datespan
  alias Crit.Setup.AnimalApi

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
      Factory.sql_insert!(:animal, to_be_found, @institution)
      Factory.sql_insert!(:animal, to_be_skipped, @institution)
      :ok
    end
    
    test "the species matters" do
      assert_available_after_the_fact(%{species_id: @bovine_id, date: @date_2})
    end

    test "the date matters" do 
      assert_available_after_the_fact(%{species_id: @bovine_id, date: @date_2})
      assert_available_after_the_fact(%{species_id: @bovine_id, date: @date_7})
      
      refute_available_after_the_fact(%{species_id: @bovine_id, date: @date_1})
      refute_available_after_the_fact(%{species_id: @bovine_id, date: @date_8})
    end

    def assert_available_after_the_fact(map) do 
      actual = AnimalApi.available_after_the_fact(map, @institution)
      assert [%{name: "bovine"}, %{name: "later"}] = actual
    end

    def refute_available_after_the_fact(map) do 
      actual = AnimalApi.available_after_the_fact(map, @institution)
      assert [] = actual
    end
  end
end
