defmodule Crit.Usables.HiddenSchemas.Use do
  use Ecto.Schema
  import Ecto.Changeset

  schema "uses" do
    field :animal_id, :id
    field :procedure_id, :id
    field :reservation_id, :id
  end

  @required [:animal_id, :procedure_id, :reservation_id]

  def changeset(a_use, attrs) do
    a_use
    |> cast(attrs, @required)
    |> foreign_key_constraint(:animal_id)
    |> foreign_key_constraint(:procedure_id)
    |> foreign_key_constraint(:reservation_id)
  end
  
  def changesets_for_new_uses(animal_ids, procedure_ids) do 
    unsaved_uses(animal_ids, procedure_ids)
    |> Enum.map(&create_changeset_with_constraints/1)
  end

  defp create_changeset_with_constraints(a_use) do 
    change(a_use)
    |> foreign_key_constraint(:animal_id)
    |> foreign_key_constraint(:procedure_id)
  end

  defp unsaved_uses(animal_ids, procedure_ids) do
    for a <- animal_ids, p <- procedure_ids do
      %__MODULE__{animal_id: a, procedure_id: p}
    end
  end
end
