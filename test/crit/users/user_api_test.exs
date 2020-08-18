defmodule Crit.Users.UserApiTest do
  use Crit.DataCase
  alias Crit.Users.UserApi
  alias Crit.Users.UserHavingToken
  alias Crit.Users.Schemas.PermissionList
  alias Crit.Exemplars.Minimal

  # Factor out verbosity. Is also a handy list of what's tested here
  def t_fresh_user_changeset(),
    do: UserApi.fresh_user_changeset()

  def t_permissioned_user(id),
    do: UserApi.permissioned_user_from_id(id, @institution)

  def t_active_users(),
    do: UserApi.active_users(@institution)

  def t_create_unactivated_user(params),
    do: UserApi.create_unactivated_user(params, @institution)

  # ------------------------------------------------------------------------

  test "the fresh/default user changeset contains permissions" do
    t_fresh_user_changeset()
    |> assert_no_changes(:permission_list)
    |> assert_data_shape(:permission_list, %PermissionList{})
  end

  # ------------------------------------------------------------------------

  describe "getting a fully permissioned user" do
    test "does not exist" do
      refute t_permissioned_user(3838)
    end

    test "brings along permission list" do
      original = Minimal.user()
      
      t_permissioned_user(original.id)
      |> assert_field(permission_list: original.permission_list)
    end
  end

  # ------------------------------------------------------------------------

  test "fetching all *active* users" do
    visible = Minimal.user()
    _invisible = Minimal.user(active: false)

    assert [retrieved] = t_active_users()
    assert_field(retrieved, auth_id: visible.auth_id)
  end

  # ------------------------------------------------------------------------

  describe "create_unactivated_user" do
    setup do
      params = Factory.string_params_for(:user, auth_id: "unique")

      %UserHavingToken{user: user, token: token} =
        t_create_unactivated_user(params) |> ok_content
      [user: user, token: token]
    end

    test "user has fields", %{user: user} do
      assert_field(user, auth_id: "unique")
    end
    
    test "token matches user", %{user: user, token: token} do 
      assert_field(token, user_id: user.id)
    end

    test "user can be retrieved", %{user: user} do
      assert [retrieved] = t_active_users()
      assert_fields(retrieved,
        auth_id: user.auth_id,
        active: true)
    end

    test "trying to reuse an auth id", %{user: original} do
      params = Factory.string_params_for(:user, auth_id: original.auth_id)
      t_create_unactivated_user(params)
      |> error_content
      |> assert_error(auth_id: "has already been taken")
    end

    test "creating with a bad param" do
      params = Factory.string_params_for(:user, auth_id: "")
      t_create_unactivated_user(params)
      |> error_content
      |> assert_error(auth_id: "can't be blank")
    end
  end
end
