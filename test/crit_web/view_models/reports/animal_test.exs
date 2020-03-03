defmodule CritWeb.ViewModels.Reports.AnimalTest do
  use ExUnit.Case
  alias CritWeb.ViewModels.Reports.Animal

  test "grouping use rows into a hierarchical form" do
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
    
    assert expected == Animal.multi_animal_uses(input)
  end
end
