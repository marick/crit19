defmodule Crit.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :auth_id, :citext, null: false
      add :password_hash, :string, default: Crit.Accounts.User.no_password_hash()
      add :display_name, :string, null: false
      add :email, :citext, null: false
      add :active, :boolean, default: true, null: false

      timestamps()
    end

    create unique_index("users", [:auth_id], name: :unique_auth_id)
  end
end
