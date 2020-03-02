defmodule Crit.Reports.AnimalReportsTest do
  use Crit.DataCase
  alias Crit.Reports.AnimalReports
  alias Crit.Exemplars.ReservationFocused

  describe "raw data on animal uses" do
    test "no animals" do
      [] = AnimalReports.use_rows(@date_1, @date_2, @institution)
    end

    test "bounds" do
      ReservationFocused.reserved!(@bovine_id,
        ["Jeff", "bossie"], ["procedure 1", "procedure 2"],
        date: @date_1)
      
      ReservationFocused.reserved!(@equine_id,
        ["Wilbur"], ["procedure 2", "procedure 1", "proca"],
        date: @date_2)

      result = 
        AnimalReports.use_rows(@date_1, @date_2, @institution)
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
        date: @date_3)

      result = 
        AnimalReports.use_rows(@date_1, @date_2, @institution)
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
        AnimalReports.use_rows(@date_1, @date_2, @institution)
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

      assert [] = AnimalReports.use_rows(@date_1, @date_2, @institution)
    end
  end
  
  def animal_procedure_count(record) do
    {record.animal_name, record.procedure_name, record.count}
  end
              
end
