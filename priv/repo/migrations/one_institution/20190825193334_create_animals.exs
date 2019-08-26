defmodule Crit.Repo.Migrations.CreateAnimals do
  use Ecto.Migration

  def change do
    create table(:animals) do
      add :name, :string, null: false
      add :species, :string, null: false
      add :lock_version, :integer, default: 1

      timestamps()
    end

  end
end
