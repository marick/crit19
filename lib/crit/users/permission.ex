defmodule Crit.Users.Permission do
  use Ecto.Schema
  import Ecto.Query
  alias Crit.Repo

  schema "permissions" do
    field :permission_id, :integer
    belongs_to :user, Crit.Users.User
  end

  def replace(user_id, permissions) do
    Repo.delete_all(by_user(user_id))
    Repo.insert_all(__MODULE__, to_rows(user_id, permissions))
  end

  def permissions(user_id) do
    Repo.all(by_user(user_id)) |> from_rows
  end

  defp to_rows(user_id, permissions) do
    Enum.map(permissions, fn p -> [user_id: user_id, permission_id: p] end)
  end

  defp from_rows(rows) do
    Enum.map(rows, fn %{permission_id: p} -> p end)
  end

  defp by_user(user_id), do: from p in __MODULE__, where: [user_id: ^user_id]
end
