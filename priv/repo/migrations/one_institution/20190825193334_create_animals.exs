defmodule Crit.Repo.Migrations.CreateAnimals do
  use Ecto.Migration

  def change do
    create table(:animals) do
      add :name, :string, null: false
      add :species, :string, null: false
      add :lock_version, :integer, default: 1

      timestamps()
    end

    create table("scheduled_unavailabilities") do
      add :animal_id, references("animals", on_delete: :delete_all), null: false
      add :timespan, :tsrange
      add :reason, :text, null: false
      
      timestamps()
    end
    create index("scheduled_unavailabilities", :animal_id)
    create index("scheduled_unavailabilities", :timespan, using: :gist)
  end
end
