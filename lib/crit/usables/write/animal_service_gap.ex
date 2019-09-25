defmodule Crit.Usables.Write.AnimalServiceGap do
  use Ecto.Schema
  import Ecto.Changeset

  schema "animal__service_gap" do
    field :animal_id, :integer
    field :service_gap_id, :integer
  end

  @required [:animal_id, :service_gap_id]

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end

  def new(animal_id, service_gap_id),
    do: %__MODULE__{animal_id: animal_id, service_gap_id: service_gap_id}
end
