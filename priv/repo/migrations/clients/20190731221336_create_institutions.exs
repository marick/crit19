defmodule Crit.Repo.Migrations.CreateInstitutions do
  use Ecto.Migration

  def change do
    create table(:institutions) do
      add :display_name, :string, null: false
      add :short_name, :string, null: false
      add :prefix, :string
      add :repo, :string

      timestamps()
    end

  end
end
