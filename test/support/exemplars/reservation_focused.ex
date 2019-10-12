defmodule Crit.Exemplars.ReservationFocused do
  use ExUnit.CaseTemplate
  use Crit.Global.Default
  alias Crit.Usables.Write
  alias Crit.Usables
  alias Crit.Sql


  defp named_thing_inserter(template) do 
    fn name ->
      template
      |> Map.put(:name, name)
      |> Sql.insert!(@institution)
    end
  end

  defp inserted_named_ids(names, template) do
    names
    |> Enum.map(named_thing_inserter template)
    |> EnumX.ids
  end

  # Because these have no associated in-service and out-of-service dates,
  # they can be reserved at any time. 
  def inserted_animal_ids(names, species_id) do
    inserted_named_ids names, %Write.Animal{
      species_id: species_id
    }
  end

  def inserted_procedure_ids(names) do
    inserted_named_ids names, %Usables.Procedure{}
  end
end


