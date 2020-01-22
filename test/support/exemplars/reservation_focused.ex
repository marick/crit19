defmodule Crit.Exemplars.ReservationFocused do
  use ExUnit.CaseTemplate
  use Crit.Global.Constants
  alias Crit.Setup.Schemas.{Animal, Procedure}
  alias Crit.Sql
  alias Ecto.Datespan


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

  # These are available for any reasonable reservation date.
  def inserted_animal_ids(names, species_id) do
    inserted_named_ids names, %Animal{
      species_id: species_id,
      span: Datespan.inclusive_up(~D[1990-01-01])
    }
  end

  def inserted_procedure_ids(names) do
    inserted_named_ids names, %Procedure{}
  end
end


