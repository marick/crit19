defmodule Crit.Users.PasswordTest do
  use Crit.DataCase
  alias Crit.Users
  # alias Crit.Users.User
  alias Crit.Users.Password
  alias Crit.Examples.PasswordFocused
  alias Crit.Sql

  @moduledoc """
  Working with passwords through the Users interface. 
  See also users/internal/password_test.exs
  """

  @default_institution "critter4us"
  
  
  setup do
    user = Factory.build(:user) |> Sql.insert!(@default_institution)
    assert Password.count_for(user.auth_id) == 0
    [user: user]
  end

  setup do
    institution = Atom.to_string(__MODULE__)
    server = Sql.PrefixServer.start_link("irrelevant")
    Sql.Servers.put(institution, server)
    []
  end
  
  describe "setting a password..." do
    test "successfully, for the first time", %{user: user} do
      password = "password"

      assert :ok == Users.set_password(user.auth_id, PasswordFocused.params(password))
      assert Password.count_for(user.auth_id) == 1
      assert {:ok, user.id} == Users.check_password(user.auth_id, password)
    end

    test "successfully replacing the old one", %{user: user} do
      password__old = "password"
      password__NEW = "different"

      assert :ok == Users.set_password(user.auth_id, PasswordFocused.params(password__old))
      assert :ok == Users.set_password(user.auth_id, PasswordFocused.params(password__NEW))
      
      assert Password.count_for(user.auth_id) == 1
      assert {:ok, user.id} == Users.check_password(user.auth_id, password__NEW)
      assert :error == Users.check_password(user.auth_id, password__old)
    end

    test "UNsuccessfully replacing the old one", %{user: user} do
      password__old = "password"
      password__NEW = "di"

      assert :ok == Users.set_password(user.auth_id, PasswordFocused.params(password__old))
      assert {:error, _} = Users.set_password(user.auth_id, PasswordFocused.params(password__NEW))
      
      assert Password.count_for(user.auth_id) == 1
      assert {:ok, user.id} == Users.check_password(user.auth_id, password__old)
      assert :error == Users.check_password(user.auth_id, password__NEW)
    end
  end


  describe "checking a password" do
    # Success case is tested above.
    
    test "no such user: does not leak that fact" do
      assert :error == Users.check_password("bad auth id", "password")
    end
    
    test "incorrect password: does not leak that fact" do
      user = PasswordFocused.user("password")
      assert :error == Users.check_password(user.auth_id, "WRONG_password")
    end
  end
end
