defmodule Crit.Users.UsersTest do
  use Crit.DataCase
  alias Crit.Users
  alias Crit.Users.{PasswordToken, User}
  import Crit.Test.Util

  setup do
    # Not using insert_pair because both would have same password token.
    user1 = Factory.insert(:user, password_token: Factory.build(:password_token))
    user2 = Factory.insert(:user, password_token: Factory.build(:password_token))

    [user1: user1, user2: user2]
  end


  describe "user_from_token" do
    test "token matches",  %{user1: user} do
      {:ok, fetched} = Users.user_from_token(user.password_token.text)
      assert fetched.id == user.id
    end
  end
end  
