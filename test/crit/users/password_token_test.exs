defmodule Crit.Users.PasswordTokenTest do
  use Crit.DataCase
  alias Crit.Users

  setup do
    # Not using insert_pair because both would have same password token.
    user1 = Factory.insert(:user, password_token: Factory.build(:password_token))
    user2 = Factory.insert(:user, password_token: Factory.build(:password_token))

    [user1: user1, user2: user2]
  end

  describe "creating a PasswordToken" do
    @tag :skip
    test "create" do
    end
  end

  describe "user_from_token" do
    test "token matches",  %{user1: user} do
      {:ok, fetched} = Users.user_from_token(user.password_token.text)
      assert fetched.id == user.id
    end
  end


  describe "deleting a token" do
    @tag :skip
    test "success" do
    end

    @tag :skip
    test "missing token does not throw an error" do
    end
  end
  
  describe "checking if a token exists" do
    @tag :skip
    test "yes" do
    end

    @tag :skip
    test "no" do
    end
  end


  describe "tokens and time" do
    @tag :skip
    test "tokens can expire" do
    end

    @tag :skip
    test "reading a token updates its 'time to live'" do
    end
  end
end  
