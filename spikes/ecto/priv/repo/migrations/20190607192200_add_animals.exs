defmodule Spikes.Repo.Migrations.AddAnimals do
  use Ecto.Migration

  def change do
    create table("animals") do
      add :name, :string, null: false
      add :species, :string, null: false
      timestamps()
    end

    create table("procedures") do
      add :name, :string, null: false
      timestamps()
    end

    create table("reservation_bundles") do
      add :name, :string, null: false
      timestamps()
    end

    create table("animals__reservation_bundles") do
      add :animal_id, foreign("animals"), null: false
      add :reservation_bundle_id, foreign("reservation_bundles"), null: false
    end
    create index("animals__reservation_bundles", :animal_id)
    create index("animals__reservation_bundles", :reservation_bundle_id)

    create table("reservation_bundles__procedures") do
      add :reservation_bundle_id, foreign("reservation_bundles"), null: false
      add :procedure_id, foreign("procedures"), null: false
    end
    create index("reservation_bundles__procedures", :reservation_bundle_id)
    create index("reservation_bundles__procedures", :procedure_id)
  end

  defp foreign(name), 
    do: references(name, on_delete: :delete_all)
  
end
