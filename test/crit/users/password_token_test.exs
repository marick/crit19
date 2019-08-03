defmodule Crit.Users.PasswordTokenTest do
  use Crit.DataCase
  alias Crit.Users
  alias Crit.Users.User
  alias Crit.Users.PasswordToken
  alias Crit.Sql

  @default_institution "critter4us"

  defp fresh_user(attrs \\ []) do 
    params = Factory.string_params_for(:user, attrs)
    assert {:ok, user} = Users.user_needing_activation(params)
    assert user.password_token.user_id == user.id
    user
  end
  

  describe "creating a PasswordToken" do
    test "a successful creation" do
      user = fresh_user()
      assert token = Sql.get_by(PasswordToken, [text: user.password_token.text], @default_institution)
      assert Repo.get(User, token.user_id, prefix: "demo")
    end

    test "bad user data prevents a token from being created" do
      params = Factory.string_params_for(:user, auth_id: "")
      {:error, _} = Users.user_needing_activation(params)

      assert [] = Repo.all(PasswordToken, prefix: "demo")
    end
  end

  describe "user_from_token" do
    test "token matches" do
      user = fresh_user()
      assert {:ok, _} = Users.user_from_token(user.password_token.text)
    end

    test "is not a destructive read" do
      user = fresh_user()
      assert {:ok, _} = Users.user_from_token(user.password_token.text)
      assert {:ok, _} = Users.user_from_token(user.password_token.text)
    end

    test "no match" do
      _user = fresh_user()
      assert {:error, message} = Users.user_from_token("DIFFERENT TOKEN")
      assert message =~ "DIFFERENT TOKEN"
    end
  end


  describe "deleting a token" do
    test "success" do
      retain = fresh_user()
      remove = fresh_user()
      refute retain.password_token.text == remove.password_token.text

      assert :ok == Users.delete_password_token(remove.id)
      assert {:error, _} = Users.user_from_token(remove.password_token.text)
      assert {:ok, _} = Users.user_from_token(retain.password_token.text)
    end

    test "missing token does not throw an error" do
      retain = fresh_user()
      assert :ok == Users.delete_password_token(retain.id)
      assert :ok == Users.delete_password_token(retain.id)
    end
  end
  
  describe "checking if a token exists" do
    test "yes, then no" do
      user = fresh_user()
      assert Users.user_has_password_token?(user.id)
      assert :ok == Users.delete_password_token(user.id)
      refute Users.user_has_password_token?(user.id)
    end
  end

  def set_expiration_plus_seconds(token, seconds) do
    expired = NaiveDateTime.add(PasswordToken.expiration_threshold(), seconds)
    PasswordToken.force_update(token, expired)
  end

  describe "tokens and time" do
    setup do
      user = fresh_user()
      assert Users.user_has_password_token?(user.id)
      [user: user, token: user.password_token]
    end
    
    test "tokens can expire before being 'redeemed'", %{token: token} do
      set_expiration_plus_seconds(token, -30) # too late by 30 seconds
      assert {:error, _} = Users.user_from_token(token.text)
    end

    test "reading a token updates its 'time to live'", %{token: token} do
      set_expiration_plus_seconds(token, 30) # 30 seconds to live

      token_time = fn text -> 
        %PasswordToken{updated_at: retval} = Repo.get_by(PasswordToken, [text: text], prefix: "demo")
        retval
      end

      original_time = token_time.(token.text)
      assert {:ok, user} = Users.user_from_token(token.text)
      updated_time = token_time.(token.text)

      difference =  NaiveDateTime.diff(updated_time, original_time, :second)
      assert difference > 600  # greatly changed
    end
  end

end  
