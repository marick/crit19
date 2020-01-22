defmodule Crit.Repo.Migrations.CreateInstitutions do
  use Ecto.Migration

  def change do
    create table(:institutions) do
      add :display_name, :string, null: false
      add :short_name, :string, null: false
      add :prefix, :string
      add :repo, :string
      add :timezone, :string, null: false

      timestamps()
    end

    create table(:time_slots) do
      add :name, :string, null: false
      add :start, :time, null: false
      add :duration, :integer, null: false
      add :institution_id, references(:institutions, on_delete: :delete_all), null: false
    end

    create table(:all_password_tokens) do
      add :text, :string, null: false
      add :user_id, :id, null: false
      add :institution_short_name, :string, null: false

      timestamps(inserted_at: false)
    end
    create index(:all_password_tokens, [:text])
  end
end
