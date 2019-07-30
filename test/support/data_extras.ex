defmodule Crit.DataExtras do
  import ExUnit.Assertions
  
  alias Crit.Repo
  alias Crit.Users.PermissionList
  import Ecto.Changeset


  def assert_without_permissions(user) do
    refute %PermissionList{} == user.permission_list
  end

  def age(module, id, seconds) do
    current = Repo.get(module, id, prefix: "demo")
    current
    |> change(inserted_at: NaiveDateTime.add(current.inserted_at, -1 * seconds))
    |> Repo.update(prefix: "demo")
    end
end
