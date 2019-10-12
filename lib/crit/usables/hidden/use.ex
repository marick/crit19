defmodule Crit.Usables.Hidden.Use do
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
    |> validate_required(@required)
    |> foreign_key_constraint(:animal_id)
    |> foreign_key_constraint(:procedure_id)
    |> foreign_key_constraint(:reservation_id)
  end

  def changeset_with_constraints(a_use), do: changeset(a_use, %{})

  def reservation_uses(reservation_id, animal_ids, procedure_ids) do
    for a <- animal_ids, p <- procedure_ids do
      %__MODULE__{reservation_id: reservation_id, animal_id: a, procedure_id: p}
    end
  end
end
