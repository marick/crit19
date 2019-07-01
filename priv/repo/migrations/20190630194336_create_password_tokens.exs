defmodule Crit.Repo.Migrations.CreatePasswordTokens do
  use Ecto.Migration

  def change do
    create table(:password_tokens) do
      add :text, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:password_tokens, [:text])
  end
end
