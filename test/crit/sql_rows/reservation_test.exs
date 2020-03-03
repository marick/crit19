defmodule Crit.SqlRows.ReservationTest do
  use Crit.DataCase
  alias Crit.SqlRows.Reservation
  alias Crit.Exemplars.ReservationFocused
  alias Crit.Reservations.ReservationApi
  alias Ecto.Timespan

  @date_1_to_date_2_span Timespan.customary(@date_1, @date_2)

  describe "raw data on animal uses" do
    test "no animals" do
      [] = Reservation.timespan_uses(@date_1_to_date_2_span, @institution)
    end

    test "bounds" do
      ReservationFocused.reserved!(@bovine_id,
        ["Jeff", "bossie"], ["procedure 1", "procedure 2"],
        date: @date_1)
      
      ReservationFocused.reserved!(@equine_id,
        ["Wilbur"], ["procedure 2", "procedure 1", "proca"],
        date: Date.add(@date_2, -1))

      result = 
        Reservation.timespan_uses(@date_1_to_date_2_span, @institution)
        |> Enum.map(&animal_procedure_count/1)

      assert result ==
        [{"bossie", "procedure 1", 1},
         {"bossie", "procedure 2", 1},
         {"Jeff", "procedure 1", 1},
         {"Jeff", "procedure 2", 1},
         {"Wilbur", "proca", 1},
         {"Wilbur", "procedure 1", 1},
         {"Wilbur", "procedure 2", 1}
        ]
    end

    test "animals outside of bounds are excluded" do
      ReservationFocused.reserved!(@bovine_id,
        ["Jeff", "bossie"], ["procedure 1", "procedure 2"],
        date: @date_1)
      
      ReservationFocused.reserved!(@equine_id,
        ["bossie"], ["procedure 2", "procedure 1", "proca"],
        date: @date_2) # just past boundary

      result = 
        Reservation.timespan_uses(@date_1_to_date_2_span, @institution)
        |> Enum.map(&animal_procedure_count/1)

      assert result ==
        [{"bossie", "procedure 1", 1},
         {"bossie", "procedure 2", 1},
         {"Jeff", "procedure 1", 1},
         {"Jeff", "procedure 2", 1},
        ]
    end

    test "many uses" do
      ReservationFocused.reserved!(@bovine_id,
        ["Jeff", "bossie"], ["procedure 1", "procedure 2"],
        date: @date_1)
      
      ReservationFocused.reserved!(@bovine_id,
        ["Jeff"], ["procedure 2", "procedure 1", "proca"],
        date: @date_1)

      result = 
        Reservation.timespan_uses(@date_1_to_date_2_span, @institution)
        |> Enum.map(&animal_procedure_count/1)

      assert result ==
        [{"bossie", "procedure 1", 1},
         {"bossie", "procedure 2", 1},
         {"Jeff", "proca", 1},
         {"Jeff", "procedure 1", 2},
         {"Jeff", "procedure 2", 2},
        ]
    end

    test "zero use animals are ignored" do 
      ReservationFocused.ignored_animal("Ignored animal", @bovine_id)
      ReservationFocused.ignored_procedure("Ignored procedure", @bovine_id)

      assert [] = Reservation.timespan_uses(@date_1_to_date_2_span, @institution)
    end

    test "the raw return values" do
      %{id: reservation_id} =
        ReservationFocused.reserved!(@bovine_id,
          ["Jeff"], ["procedure"],
          date: @date_1)
      {[%{id: animal_id}], [%{id: procedure_id}]} = 
        ReservationApi.all_used(reservation_id, @institution)


      actual = 
        Reservation.timespan_uses(@date_1_to_date_2_span, @institution)
      expected = [%{animal_name: "Jeff",
                    animal_id: animal_id,
                    procedure_name: "procedure",
                    procedure_id: procedure_id,
                    count: 1}]
      
      assert actual == expected
    end
  end
  
  def animal_procedure_count(record) do
    {record.animal_name, record.procedure_name, record.count}
  end
              
end
