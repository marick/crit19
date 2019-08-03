defmodule Crit.DataExtras do
  import ExUnit.Assertions
  
  alias Crit.Repo
  alias Crit.Users.PermissionList
  import Ecto.Changeset

  @default_institution "critter4us"

  def assert_without_permissions(user) do
    refute %PermissionList{} == user.permission_list
  end

  def age(module, id, seconds, institution \\ @default_institution) do
    current = Repo.get(module, id, institution)
    current
    |> change(inserted_at: NaiveDateTime.add(current.inserted_at, -1 * seconds))
    |> Repo.update(prefix: "demo")
    end
end
