defmodule Crit.Users.Api.PasswordTokenTest do
  use Crit.DataCase
  import Crit.Assertions.User
  alias Crit.Users.UserApi
  alias Crit.Users.Schemas.User
  alias Crit.Users.Schemas.PasswordToken
  alias Crit.Sql
  alias Crit.Repo
  alias Crit.Users.UserHavingToken, as: UT
  alias Crit.Exemplars.{TokenFocused, PasswordFocused}

  describe "creating a PasswordToken" do
    test "a successful creation" do
      %UT{token: token, user: user} = TokenFocused.user()

      assert token.user_id == user.id

      # User exists and is found through token.
      assert Sql.get(User, token.user_id, token.institution_short_name)

      # Token exists. 
      assert Repo.get_by(PasswordToken, user_id: user.id)
      assert Repo.get_by(PasswordToken, text: token.text)
    end

    test "bad user data prevents a token from being created" do
      too_short_auth_id = "" 
      {:error, changeset} = TokenFocused.possible_user(auth_id: too_short_auth_id)
      assert %{auth_id: ["can't be blank"]} = errors_on(changeset)
      assert [] = Repo.all(PasswordToken)
      assert [] = Sql.all(User, @institution)
    end
  end

  describe "fetching a password token" do
    setup :user_and_token

    test "token matches", %{token: token} do
      assert {:ok, retrieved} = UserApi.one_token(token.text)
      assert token == retrieved
    end

    test "is not a destructive read", %{token: token} do
      assert {:ok, _} = UserApi.one_token(token.text)
      assert {:ok, _} = UserApi.one_token(token.text)
    end

    test "no match" do
      assert {:error, message} = UserApi.one_token("DIFFERENT TOKEN")
      assert message =~ "DIFFERENT TOKEN"
    end

    @tag :skip
    test "updates the expiration date" do
      # Test this by mocking out PasswordToken.force_update and
      # checking that it's called.
      # Then test PasswordToken.force_update passing in something other
      # than utc_now
    end
  end


  describe "attempting to redeem a password token" do
    setup :user_and_token

    setup do
      [valid_password: "something horse something something"]
    end

    test "the password is acceptable",
      %{valid_password: valid_password, user: user, token: token} do
      params = PasswordFocused.params(valid_password, valid_password)
      assert_same_user(user, UserApi.redeem_password_token(token, params))
      # Token has been deleted
      refute Repo.get_by(PasswordToken, user_id: user.id)
    end

    test "something is wrong with the password", 
      %{valid_password: valid_password, token: token} do
      params = PasswordFocused.params(valid_password, "WRONG")
      assert {:error, changeset} = UserApi.redeem_password_token(token, params)
      assert %{new_password_confirmation: ["should be the same as the new password"]}
      == errors_on(changeset)
      # The token is not deleted.
      assert UserApi.one_token(token.text)
    end

    # User could hit back and redeem the token twice. Can't do any harm. 
    test "redeeming a password token twice",
      %{valid_password: valid_password, user: user, token: token} do
      params = PasswordFocused.params(valid_password, valid_password)
      UserApi.redeem_password_token(token, params)
      assert_same_user(user, UserApi.redeem_password_token(token, params))
    end
  end

  describe "deleting a token" do
    test "success" do
      %UT{token: retain} = TokenFocused.user()
      %UT{token: remove} = TokenFocused.user()
      refute retain.text == remove.text

      assert :ok == UserApi.delete_password_token(remove.text)
      assert {:error, _} = UserApi.one_token(remove.text)

      assert {:ok, _} = UserApi.one_token(retain.text)
    end

    test "missing token does not throw an error" do
      %{token: remove} = TokenFocused.user()
      assert :ok == UserApi.delete_password_token(remove.text)
      assert :ok == UserApi.delete_password_token(remove.text)
    end
  end
  
  describe "checking if a token exists" do
    test "yes, then no" do
      %{token: token} = TokenFocused.user()
      assert Repo.get_by(PasswordToken, text: token.text)
      assert :ok == UserApi.delete_password_token(token.text)
      refute Repo.get_by(PasswordToken, text: token.text)
    end
  end

  describe "tokens and time" do
    setup :user_and_token
    
    test "tokens can expire before being 'redeemed'", %{token: token} do
      move_expiration_backward_by_seconds(token, 30) # `now` is now too late.
      assert {:error, _} = UserApi.one_token(token.text)
    end

    test "reading a token updates its 'time to live'", %{token: token} do
      advance_expiration_by_seconds(token, 30) # 30 seconds to live

      token_time = fn text -> 
        %PasswordToken{updated_at: retval} =
          Repo.get_by(PasswordToken, [text: text])
        retval
      end

      original_time = token_time.(token.text)
      assert {:ok, user} = UserApi.one_token(token.text)
      updated_time = token_time.(token.text)

      difference =  NaiveDateTime.diff(updated_time, original_time, :second)
      assert difference > 600  # greatly changed
    end
  end

  defp advance_expiration_by_seconds(token, seconds) do
    changed = NaiveDateTime.add(PasswordToken.expiration_threshold(), seconds)
    PasswordToken.force_update(token, changed)
  end

  defp move_expiration_backward_by_seconds(token, seconds),
    do: advance_expiration_by_seconds(token, -seconds)

  defp user_and_token(_) do 
    %{user: inserted, token: token} = TokenFocused.user()
    [user: inserted, token: token]
  end
  
end  
