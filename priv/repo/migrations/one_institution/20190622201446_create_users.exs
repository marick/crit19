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

    create table(:passwords) do
      add :hash, :string, null: false
      add :auth_id,
        # User records are never supposed to be deleted.
        references(:users, column: :auth_id, type: :citext, on_delete: :restrict),
        null: false

      timestamps()
    end
    create unique_index(:passwords, [:auth_id])

    create table(:permission_lists) do
        # User records are never supposed to be deleted.
      add :user_id, references(:users, on_delete: :restrict), null: false
      add :manage_and_create_users, :boolean, null: false
      add :manage_animals, :boolean, null: false
      add :make_reservations, :boolean, null: false
      add :view_reservations, :boolean, null: false

      timestamps()
    end
    create index("permission_lists", :user_id)
  end
end
