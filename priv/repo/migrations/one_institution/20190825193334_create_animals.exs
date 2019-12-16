defmodule Crit.Repo.Migrations.CreateAnimals do
  use Ecto.Migration

  def change do
    create table(:species) do
      add :name, :citext, null: false
    end
    
    create table(:animals) do
      add :name, :citext, null: false
      add :in_service_date, :date, null: false
      add :out_of_service_date, :date,              null: true
      add :span, :daterange, null: true
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
    create index("animals", :span, using: :gist)
    
    create table("service_gaps") do
      add :animal_id, references("animals", on_delete: :restrict), null: false
      add :span, :daterange, null: false
      add :reason, :text, null: false
    end
    create index("service_gaps", :span, using: :gist)
  end
end
