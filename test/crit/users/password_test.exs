defmodule Crit.Users.PasswordTest do
  use Crit.DataCase
  alias Crit.Users
  # alias Crit.Users.User
  alias Pile.Changeset
  alias Crit.Users.Password

  @moduledoc """
  Working with passwords through the Users interface. 
  See also users/internal/password_test.exs
  """

  def user_without_password do
    user = Factory.insert(:user)
    assert Password.count_for(user.auth_id) == 0
    user
  end
  
  setup do
    [user: user_without_password()]
  end
  
  test "a blank changeset" do
    assert changeset = Users.fresh_password_changeset()
    refute Changeset.represents_form_errors?(changeset)
    assert Changeset.empty_text_field?(changeset, :new_password)
    assert Changeset.empty_text_field?(changeset, :new_password_confirmation)
    # Be very sure confidential data doesn't leak
    assert Changeset.current_value(changeset, :hash) == nil
    assert Changeset.current_value(changeset, :auth_id) == nil
  end
  
  describe "setting a password..." do
    test "successfully, for the first time", %{user: user} do
      password = "password"
      params = %{"new_password" => password,
                 "new_password_confirmation" => password}

      assert :ok == Users.set_password(user.auth_id, params)
      
      assert Password.count_for(user.auth_id) == 1
      assert :ok == Users.check_password(user.auth_id, password)
    end

    test "successfully replacing the old one", %{user: user} do
      password__old = "password"
      password__NEW = "different"

      params = fn password ->
        %{"new_password" => password, "new_password_confirmation" => password}
      end
      
      assert :ok == Users.set_password(user.auth_id, params.(password__old))
      assert :ok == Users.set_password(user.auth_id, params.(password__NEW))
      
      assert Password.count_for(user.auth_id) == 1
      assert :ok == Users.check_password(user.auth_id, password__NEW)
      assert :error == Users.check_password(user.auth_id, password__old)
    end

    test "UNsuccessfully replacing the old one", %{user: user} do
      password__old = "password"
      password__NEW = "di"

      params = fn password ->
        %{"new_password" => password, "new_password_confirmation" => password}
      end
      
      assert :ok == Users.set_password(user.auth_id, params.(password__old))
      assert {:error, _} = Users.set_password(user.auth_id, params.(password__NEW))
      
      assert Password.count_for(user.auth_id) == 1
      assert :ok == Users.check_password(user.auth_id, password__old)
      assert :error == Users.check_password(user.auth_id, password__NEW)
    end
  end


  describe "checking a password" do
    setup do
    end
    
    @tag :skip
    test "success" do
    end
    
    @tag :skip
    test "no such user: does not leak that fact" do
    end
    
    @tag :skip
    test "incorrect password: does not leak that fact" do
    end
  end
end
