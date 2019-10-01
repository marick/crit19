defmodule Crit.Users.Api.UserTest do
  use Crit.DataCase
  alias Crit.Users
  alias Ecto.ChangesetX
  alias Crit.Users.PermissionList
  alias Crit.Exemplars.{TokenFocused, Minimal}

  # Factor out verbosity. Is also a handy list of what's tested here
  # 
  def ut_permissioned_user(id),
    do: Users.permissioned_user_from_id(id, @institution)

  def ut_active_users(),
    do: Users.active_users(@institution)

  def ut_fresh_user_changeset(),
    do: Users.fresh_user_changeset()

  ####

  test "the fresh/default user changeset contains permissions" do
    changeset = ut_fresh_user_changeset()
    assert %PermissionList{} = changeset.data.permission_list

    assert changeset.valid?
    refute ChangesetX.represents_form_errors?(changeset)
    refute ChangesetX.has_changes_for?(changeset, :permission_list)
    
    # for further tests, see `/internal`.
  end

  # See password_token_tests for other tests of initial user creation.
  test "trying to reuse an auth id" do
    assert {:ok, %{user: user}} = TokenFocused.possible_user()
    assert {:error, changeset} = TokenFocused.possible_user(auth_id: user.auth_id)
    assert errors_on(changeset) == %{auth_id: ["has already been taken"]}
  end

  describe "getting a fully permissioned user" do
    test "does not exist" do
      refute ut_permissioned_user(3838)
    end

    test "does exist" do
      original = Minimal.user()
      assert fetched = ut_permissioned_user(original.id)
      assert fetched.permission_list == original.permission_list
    end
  end

  test "fetching all *active* users" do
    visible = Minimal.user()
    _invisible = Minimal.user(active: false)

    assert [retrieved] = ut_active_users()
    assert retrieved.auth_id == visible.auth_id
  end
end
