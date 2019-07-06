defmodule Crit.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :auth_id, :citext, null: false
      add :display_name, :string, null: false
      add :email, :string, null: false
      add :active, :boolean, null: false

      timestamps()
    end
    create unique_index("users", [:auth_id], name: :unique_auth_id)

    create table(:password_tokens) do
      add :text, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps()
    end
    create index(:password_tokens, [:text])

    create table(:passwords) do
      add :hash, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end
    create unique_index(:passwords, [:user_id])

    create table(:permissions) do
      add :permission_id, :int, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false
    end
    create index("permissions", :permission_id)
    create index("permissions", :user_id)
  end
end
