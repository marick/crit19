defmodule Crit.Repo.Migrations.CreateReservation do
  use Ecto.Migration

  def change do
    create table(:reservation) do
      add :animal_ids, {:array, :id}, default: [], null: false
      add :procedure_ids, {:array, :id}, default: [], null: false
      add :timespan, :tsrange, null: false
      timestamps()
    end

  end
end
