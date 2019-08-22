defmodule Crit.DataExtras do
  import ExUnit.Assertions
  alias Crit.Users.{PermissionList, UniqueId}
  use Crit.Institutions.Default


  def assert_without_permissions(user) do
    refute %PermissionList{} == user.permission_list
  end

  def assert_ok_unique_id(required_user_id,
                          {:ok, %UniqueId{} = actual}) do
    required_id = UniqueId.new(required_user_id, @default_short_name)
    assert required_id == actual
  end

  
end
