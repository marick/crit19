defmodule CritBiz.ViewModels.Reports.Animal do
  use Ecto.Schema

  def multi_animal_uses(raw_rows) do
    raw_rows
    |> Enum.chunk_by(&(&1.animal_name))
    |> Enum.map(&animal_uses/1)
  end

  defp animal_uses([first | _rest] = animal_uses) do
    procedure_summary = fn animal_use ->
      %{procedure: {animal_use.procedure_name, animal_use.procedure_id},
        count: animal_use.count}
    end
  
    %{animal: {first.animal_name, first.animal_id},
      procedures: Enum.map(animal_uses, procedure_summary)
     }
  end
end
