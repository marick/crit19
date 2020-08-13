defmodule Crit.Assertions.User do
  use Crit.TestConstants
  use FlowAssertions.Define
  import ExUnit.Assertions
  alias Crit.Users.Schemas.PermissionList
  alias Crit.Users.UniqueId
  alias Crit.Users.Schemas.User

  defchain assert_without_permissions(user), 
    do: refute %PermissionList{} == user.permission_list

  # assert_same_user indicates that the second argument represents the
  # same user in the same institution as the first. The institution is
  # always the default institution.
  defchain assert_same_user(%User{} = user, arg1),
    do: assert_same_user(user.id, arg1)
  
  defchain assert_same_user(required_user_id, {:ok, %UniqueId{} = actual}),
    do: assert_same_user(required_user_id, actual)

  defchain assert_same_user(required_user_id, %UniqueId{} = actual),
    do: assert UniqueId.new(required_user_id, @institution) == actual
end
