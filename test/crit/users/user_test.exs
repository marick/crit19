defmodule Crit.Users.UserTest do
  use Crit.DataCase
  alias Crit.Users

  describe "fetching a user by the auth id" do
    test "success" do
      user = Factory.insert(:user)
      assert {:ok, fetched} = Users.user_from_auth_id(user.auth_id)
      assert fetched.auth_id == user.auth_id
    end

    test "failure" do
      assert {:error, message} = Users.user_from_auth_id("missing")
      assert message =~ "no such user 'missing'"
    end
  end

  
end

