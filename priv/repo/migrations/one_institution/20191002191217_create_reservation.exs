defmodule Crit.Repo.Migrations.CreateReservation do
  use Ecto.Migration

  def change do
    create table(:reservations) do
      add :species_id, references("species", on_delete: :restrict), null: false
      add :timespan, :tsrange, null: false
      timestamps()
    end

    create table("uses") do
      add :animal_id, references("animals"), null: false
      add :procedure_id, references("procedures"), null: false
      add :reservation_id, references("reservations"), null: false
    end
  end
end
