defmodule Crit.Usables.AnimalApi do
  use Crit.Global.Constants
  # alias Crit.Sql
  alias Crit.Usables.Animal.Read
  # import Ecto.ChangesetX, only: [ensure_forms_display_errors: 1]

  
  def showable!(id, institution) do
    case Read.one([id: id], institution) do
      nil ->
        raise KeyError, "No animal id #{id}"
      animal ->
        Read.put_virtual_fields(animal)
    end
  end

  def showable_by(field, value, institution) do
    case Read.one([{field, value}], institution) do
      nil ->
        nil
      animal ->
        Read.put_virtual_fields(animal)
    end
  end
    
  def ids_to_animals(ids, institution) do
    ids
    |> Read.ids_to_animals(institution)
    |> Enum.map(&Read.put_virtual_fields/1)
  end  
end
