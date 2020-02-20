defmodule Crit.Reservations.HiddenSchemas.Use do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Setup.Schemas.{Animal,Procedure}

  schema "uses" do
    belongs_to :animal, Animal
    belongs_to :procedure, Procedure
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

  def cross_product(animal_ids, procedure_ids) do
    for a <- animal_ids, p <- procedure_ids do
      %{animal_id: a, procedure_id: p}
    end
  end
end
