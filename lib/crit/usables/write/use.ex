defmodule Crit.Usables.Write.Use do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Timespan
  alias Crit.Sql


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
end
