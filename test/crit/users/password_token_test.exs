defmodule Crit.Users.PasswordTokenTest do
  use Crit.DataCase
  alias Crit.Users
  alias Crit.Users.User
  alias Crit.Users.PasswordToken
  alias Crit.Users.PasswordToken2
  alias Crit.Sql
  alias Crit.Repo

  defp fresh_user(attrs \\ []) do 
    params = Factory.string_params_for(:user, attrs)
    assert {:ok, %{user: user, token: token}} =
      Users.create_unactivated_user2(params, @default_institution)
    assert user.display_name == params["display_name"]
    assert Repo.get_by(PasswordToken2, user_id: user.id)
    user
  end
  

  describe "creating a PasswordToken" do
    test "a successful creation" do
      fresh_user()
      assert [token] = Repo.all(PasswordToken2)
      assert Sql.get(User, token.user_id, token.institution_short_name)
    end

    @tag :skip
    test "bad user data prevents a token from being created" do
      params = Factory.string_params_for(:user, auth_id: "")
      {:error, _} = Users.create_unactivated_user(params, @default_institution)

      assert [] = Repo.all(PasswordToken2)
    end
  end

  describe "user_from_token" do
    @tag :skip
    test "token matches" do
      user = fresh_user()
      assert {:ok, _} = Users.user_from_token(user.password_token.text, @default_institution)
    end

    @tag :skip
    test "is not a destructive read" do
      user = fresh_user()
      assert {:ok, _} = Users.user_from_token(user.password_token.text, @default_institution)
      assert {:ok, _} = Users.user_from_token(user.password_token.text, @default_institution)
    end

    @tag :skip
    test "no match" do
      _user = fresh_user()
      assert {:error, message} = Users.user_from_token("DIFFERENT TOKEN", @default_institution)
      assert message =~ "DIFFERENT TOKEN"
    end
  end


  describe "deleting a token" do
    @tag :skip
    test "success" do
      retain = fresh_user()
      remove = fresh_user()
      refute retain.password_token.text == remove.password_token.text

      assert :ok == Users.delete_password_token(remove.id, @default_institution)
      assert {:error, _} = Users.user_from_token(remove.password_token.text, @default_institution)
      assert {:ok, _} = Users.user_from_token(retain.password_token.text, @default_institution)
    end

    @tag :skip
    test "missing token does not throw an error" do
      retain = fresh_user()
      assert :ok == Users.delete_password_token(retain.id, @default_institution)
      assert :ok == Users.delete_password_token(retain.id, @default_institution)
    end
  end
  
  describe "checking if a token exists" do
    @tag :skip
    test "yes, then no" do
      user = fresh_user()
      assert Users.user_has_password_token?(user.id, @default_institution)
      assert :ok == Users.delete_password_token(user.id, @default_institution)
      refute Users.user_has_password_token?(user.id, @default_institution)
    end
  end

  def set_expiration_plus_seconds(token, seconds) do
    expired = NaiveDateTime.add(PasswordToken.expiration_threshold(), seconds)
    PasswordToken.force_update(token, expired, @default_institution)
  end

  describe "tokens and time" do
    @tag :skip
    setup do
      user = fresh_user()
      assert Users.user_has_password_token?(user.id, @default_institution)
      [user: user, token: user.password_token]
    end
    
    @tag :skip
    test "tokens can expire before being 'redeemed'", %{token: token} do
      set_expiration_plus_seconds(token, -30) # too late by 30 seconds
      assert {:error, _} = Users.user_from_token(token.text, @default_institution)
    end

    @tag :skip
    test "reading a token updates its 'time to live'", %{token: token} do
      set_expiration_plus_seconds(token, 30) # 30 seconds to live

      token_time = fn text -> 
        %PasswordToken{updated_at: retval} =
          Sql.get_by(PasswordToken, [text: text], @default_institution)
        retval
      end

      original_time = token_time.(token.text)
      assert {:ok, user} = Users.user_from_token(token.text, @default_institution)
      updated_time = token_time.(token.text)

      difference =  NaiveDateTime.diff(updated_time, original_time, :second)
      assert difference > 600  # greatly changed
    end
  end

end  
