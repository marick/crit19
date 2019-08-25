defmodule Crit.Repo.Migrations.CreateAnimals do
  use Ecto.Migration

  def change do
    create table(:animals) do
      add :name, :string
      add :species, :string
      add :lock_version, :integer

      timestamps()
    end

  end
end
