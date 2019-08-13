defmodule Crit.Users.PasswordTokenTest do
  use Crit.DataCase
  alias Crit.Users
  alias Crit.Users.User
  alias Crit.Users.PasswordToken
  alias Crit.Sql
  alias Crit.Repo

  defp fresh_user(attrs \\ []) do 
    params = Factory.string_params_for(:user, attrs)
    result = Users.create_unactivated_user(params, @default_short_name)
    assert {:ok, %{user: user, token: token}} = result
      
    assert user.display_name == params["display_name"]
    assert Repo.get_by(PasswordToken, user_id: user.id)
    result
  end
  

  describe "creating a PasswordToken" do
    test "a successful creation" do
      fresh_user()
      assert [token] = Repo.all(PasswordToken)
      assert Sql.get(User, token.user_id, token.institution_short_name)
    end

    test "bad user data prevents a token from being created" do
      params = Factory.string_params_for(:user, auth_id: "")
      {:error, changeset} = Users.create_unactivated_user(params, @default_short_name)
      assert %{auth_id: ["can't be blank"]} = errors_on(changeset)
      assert [] = Repo.all(PasswordToken)
    end
  end

  describe "fetching a password token" do
    setup :user_and_token

    test "token matches", %{token: token} do
      assert {:ok, retrieved} = Users.one_token(token.text)
      assert token == retrieved
    end

    test "is not a destructive read", %{token: token} do
      assert {:ok, _} = Users.one_token(token.text)
      assert {:ok, _} = Users.one_token(token.text)
    end

    test "no match" do
      assert {:error, message} = Users.one_token("DIFFERENT TOKEN")
      assert message =~ "DIFFERENT TOKEN"
    end
  end    
    

  describe "deleting a token" do
    test "success" do
      {:ok, %{token: retain}} = fresh_user()
      {:ok, %{token: remove}} = fresh_user()
      refute retain.text == remove.text

      assert :ok == Users.delete_password_token(remove.text)
      assert {:error, _} = Users.one_token(remove.text)
      assert {:ok, _} = Users.one_token(retain.text)
    end

    test "missing token does not throw an error" do
      {:ok, %{token: retain}} = fresh_user()
      assert :ok == Users.delete_password_token(retain.text)
      assert :ok == Users.delete_password_token(retain.text)
    end
  end
  
  describe "checking if a token exists" do
    test "yes, then no" do
      {:ok, %{token: token}} = fresh_user()
      assert Repo.get_by(PasswordToken, text: token.text)
      assert :ok == Users.delete_password_token(token.text)
      refute Repo.get_by(PasswordToken, text: token.text)
    end
  end

  describe "tokens and time" do
    setup :user_and_token
    
    test "tokens can expire before being 'redeemed'", %{token: token} do
      move_expiration_backward_by_seconds(token, 30) # `now` is now too late.
      assert {:error, _} = Users.one_token(token.text)
    end

    test "reading a token updates its 'time to live'", %{token: token} do
      advance_expiration_by_seconds(token, 30) # 30 seconds to live

      token_time = fn text -> 
        %PasswordToken{updated_at: retval} =
          Repo.get_by(PasswordToken, [text: text])
        retval
      end

      original_time = token_time.(token.text)
      assert {:ok, user} = Users.one_token(token.text)
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
    {:ok, %{user: inserted, token: token}} = fresh_user()
    [user: inserted, token: token]
  end
  

end  
