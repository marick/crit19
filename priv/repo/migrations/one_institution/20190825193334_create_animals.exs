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
      add :available, :boolean, default: true
      add :lock_version, :integer, default: 1

      timestamps()
    end
    create unique_index("animals", [:name, :available],
      name: :unique_available_names)

    create table("service_gaps") do
      add :gap, :daterange, null: false
      add :reason, :text, null: false
    end
    create index("service_gaps", :gap, using: :gist)

    create table("animal__service_gap") do
      add :animal_id,
        references("animals", on_delete: :delete_all), null: false
      add :service_gap_id,
        references("service_gaps", on_delete: :delete_all), null: false
    end
    create index("animal__service_gap", :animal_id)
  end
end
