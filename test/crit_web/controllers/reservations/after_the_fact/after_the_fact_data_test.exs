defmodule CritWeb.Reservations.AfterTheFactDataTest do
  use Crit.DataCase, async: true
  alias CritWeb.Reservations.AfterTheFactData, as: Data
  alias Ecto.Timespan
  alias Ecto.ChangesetX

  describe "processing of SpeciesAndTime" do
    test "success" do
      params = %{species_id: to_string(@bovine_id),
                 date: "2019-01-01",
                 date_showable_date: "January 1, 2019",
                 time_slot_id: "1",
                 institution: @institution}

      expected_span =
        Timespan.from_date_time_and_duration(~D[2019-01-01], ~T[08:00:00], 4 * 60)

      assert {:ok, data} = ChangesetX.realize_struct(params, Data.SpeciesAndTime)
      data
      |> assert_fields(
           species_id: @bovine_id,
           date: ~D[2019-01-01],
           time_slot_id: 1,
           span: expected_span
         )
    end
  end


  describe "processing of Animals" do
    test "success" do
      params = %{"chosen_animal_ids" => %{"8" => "true", "1" => "true"},
                 "transaction_key" => "uuid"}

      assert {:ok, data} = ChangesetX.realize_struct(params, Data.Animals)
      
      assert_lists_equal [1, 8], data.chosen_animal_ids
      assert "uuid" == data.transaction_key
    end
  end  
end
