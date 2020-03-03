defmodule Crit.Reports.AnimalReportsTest do
  use Crit.DataCase
  alias Crit.Reports.AnimalReports
  alias Crit.Exemplars.ReservationFocused
  alias Crit.Reservations.ReservationApi
  alias Ecto.Timespan

  @date_1_to_date_2_span Timespan.customary(@date_1, @date_2)

  describe "raw data on animal uses" do
    test "no animals" do
      [] = AnimalReports.use_rows(@date_1_to_date_2_span, @institution)
    end

    test "bounds" do
      ReservationFocused.reserved!(@bovine_id,
        ["Jeff", "bossie"], ["procedure 1", "procedure 2"],
        date: @date_1)
      
      ReservationFocused.reserved!(@equine_id,
        ["Wilbur"], ["procedure 2", "procedure 1", "proca"],
        date: Date.add(@date_2, -1))

      result = 
        AnimalReports.use_rows(@date_1_to_date_2_span, @institution)
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
        AnimalReports.use_rows(@date_1_to_date_2_span, @institution)
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
        AnimalReports.use_rows(@date_1_to_date_2_span, @institution)
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

      assert [] = AnimalReports.use_rows(@date_1_to_date_2_span, @institution)
    end

    test "the raw return values" do
      %{id: reservation_id} =
        ReservationFocused.reserved!(@bovine_id,
          ["Jeff"], ["procedure"],
          date: @date_1)
      {[%{id: animal_id}], [%{id: procedure_id}]} = 
        ReservationApi.all_used(reservation_id, @institution)


      actual = 
        AnimalReports.use_rows(@date_1_to_date_2_span, @institution)
      expected = [%{animal_name: "Jeff",
                    animal_id: animal_id,
                    procedure_name: "procedure",
                    procedure_id: procedure_id,
                    count: 1}]
      
      assert actual == expected
    end
  end

  test "grouping into a hierarchical form" do
    jeff_id = 1
    proc1_id = 2
    proc2_id = 3
    zeb_id = 4
    

    input = [%{animal_name: "Jeff",
               animal_id: jeff_id,
               procedure_name: "proc",
               procedure_id: proc1_id,
               count: 1},
             %{animal_name: "Jeff",
               animal_id: jeff_id,
               procedure_name: "proc2",
               procedure_id: proc2_id,
               count: 2},                 
             %{animal_name: "zeb",
               animal_id: zeb_id,
               procedure_name: "proc2",
               procedure_id: proc2_id,
               count: 3}                  
            ]
    expected = [%{animal: {"Jeff", jeff_id},
                  procedures: [%{procedure: {"proc", proc1_id},
                                 count: 1},
                               %{procedure: {"proc2", proc2_id},
                                 count: 2}]},
                %{animal: {"zeb", zeb_id},
                  procedures: [%{procedure: {"proc2", proc2_id},
                                 count: 3}]}
               ]
    
    assert expected == AnimalReports.structurize_uses(input)
  end
  
  def animal_procedure_count(record) do
    {record.animal_name, record.procedure_name, record.count}
  end
              
end
