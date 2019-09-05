defmodule Crit.Repo.Migrations.CreateAnimals do
  use Ecto.Migration

  def change do
    create table(:species) do
      add :name, :string, null: false
    end
    
    create table(:animals) do
      add :name, :string, null: false
      # Species cannot be deleted, for the sake of consistency.
      # Instead, all animals of that species should become unavailable.
      # This allows history to be preserved.
      add :species_id, references("species", on_delete: :restrict), null: false
      add :lock_version, :integer, default: 1

      timestamps()
    end

    create table("scheduled_unavailabilities") do
      add :animal_id, references("animals", on_delete: :delete_all), null: false
      add :datespan, :daterange
      add :reason, :text, null: false
      
      timestamps()
    end
    create index("scheduled_unavailabilities", :animal_id)
    create index("scheduled_unavailabilities", :datespan, using: :gist)
  end
end
