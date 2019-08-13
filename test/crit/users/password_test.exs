defmodule Crit.Users.PasswordTest do
  use Crit.DataCase
  alias Crit.Users
  # alias Crit.Users.User
  alias Crit.Users.Password
  alias Crit.Exemplars.{PasswordFocused, Minimal}

  @moduledoc """
  Working with passwords through the Users interface. 
  See also users/internal/password_test.exs
  """

  
  setup do
    [user: Minimal.user()]
  end

  describe "setting a password..." do
    test "successfully, for the first time", %{user: user} do
      password = "password"

      assert :ok == set(user.auth_id, password)
      assert has_password?(user.auth_id)
      assert {:ok, user.id} == check(user.auth_id, password)
    end

    test "successfully replacing the old one", %{user: user} do
      password__old = "password"
      password__NEW = "different"

      assert :ok == set(user.auth_id, password__old)
      assert :ok == set(user.auth_id, password__NEW)
      
      assert has_password?(user.auth_id)
      assert {:ok, user.id} == check(user.auth_id, password__NEW)
      assert :error == check(user.auth_id, password__old)
    end

    test "UNsuccessfully replacing the old one", %{user: user} do
      password__old = "password"
      password__SHORT = "di"

      assert :ok == set(user.auth_id, password__old)
      assert {:error, _} = set(user.auth_id, password__SHORT)
      
      assert has_password?(user.auth_id)
      assert {:ok, user.id} == check(user.auth_id, password__old)
      assert :error == check(user.auth_id, password__SHORT)
    end
  end


  describe "checking a password" do
    # Success case is tested above.
    
    test "no such user: does not leak that fact" do
      assert :error == check("bad auth id", "password")
    end
    
    test "incorrect password: does not leak that fact" do
      user = PasswordFocused.user("password")
      assert :error == check(user.auth_id, "WRONG_password")
    end
  end

  # Util

  def set(auth_id, password) do 
    Users.set_password(
      auth_id, PasswordFocused.params(password), @default_short_name)
  end

  def has_password?(auth_id) do
    case Password.count_for(auth_id, @default_short_name) do
      0 -> false
      1 -> true
      n -> raise("There can't be #{n} passwords.")
    end
  end

  def check(auth_id, password) do 
    Users.check_password(auth_id, password, @default_short_name)
  end
end
