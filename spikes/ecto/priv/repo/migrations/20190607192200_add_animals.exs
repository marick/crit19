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

    create table("scheduled_unavailabilities") do
      add :animal_id, references("animals"), null: false
      add :interval, :daterange
      add :reason, :text, null: false
      
      timestamps()
    end
    create index("scheduled_unavailabilities", :animal_id)
    create index("scheduled_unavailabilities", :interval, using: :gist)


    create table("reservation_bundles") do
      add :name, :string, null: false
      timestamps()
    end

    create table("animals__reservation_bundles") do
      add :animal_id, references("animals"), null: false
      add :reservation_bundle_id, references("reservation_bundles"), null: false
    end
    create index("animals__reservation_bundles", :animal_id)
    create index("animals__reservation_bundles", :reservation_bundle_id)

    create table("reservation_bundles__procedures") do
      add :reservation_bundle_id, references("reservation_bundles"), null: false
      add :procedure_id, references("procedures"), null: false
    end
    create index("reservation_bundles__procedures", :reservation_bundle_id)
    create index("reservation_bundles__procedures", :procedure_id)
  end
end
