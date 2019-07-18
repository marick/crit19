defmodule Crit.DataExtras do
  import ExUnit.Assertions

  alias Crit.Users.PermissionList


  def assert_without_permissions(user) do
    refute %PermissionList{} == user.permission_list
  end
  
end
