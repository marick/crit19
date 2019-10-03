defmodule Crit.Repo.Migrations.CreateReservation do
  use Ecto.Migration

  def change do
    create table(:reservation) do
      add :species_id, references("species", on_delete: :restrict), null: false
      add :animal_ids, {:array, :id}, default: [], null: false
      add :procedure_ids, {:array, :id}, default: [], null: false
      add :timespan, :tsrange, null: false
      timestamps()
    end

  end
end
