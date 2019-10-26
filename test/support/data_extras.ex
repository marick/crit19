defmodule Crit.DataExtras do
  import ExUnit.Assertions
  alias Crit.Users.{PermissionList, UniqueId}
  use Crit.Global.Default


  def assert_without_permissions(user) do
    refute %PermissionList{} == user.permission_list
  end

  def assert_ok_unique_id(required_user_id,
                          {:ok, %UniqueId{} = actual}) do
    required_id = UniqueId.new(required_user_id, @institution)
    assert required_id == actual
  end
end
