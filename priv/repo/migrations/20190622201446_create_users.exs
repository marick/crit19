defmodule Crit.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :name, :string, null: false
      add :email, :citext, null: false
      add :password_hash, :string
      add :active, :boolean, default: true, null: false

      timestamps()
    end

    create unique_index("users", [:email, :active], name: :unique_active_email)


  end
end
