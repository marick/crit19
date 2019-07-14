defmodule Crit.Users.Internal.UserTest do
  use Crit.DataCase
  alias Crit.Users.User
  alias Pile.Changeset

  # Other tests are in ../user_test.exs


  describe "the default/blank changeset" do 
    test "creation without data" do
      assert changeset = User.default_changeset(%User{})
      refute Changeset.represents_form_errors?(changeset)
      assert Changeset.empty_text_field?(changeset, :auth_id)
      assert Changeset.empty_text_field?(changeset, :display_name)
      assert Changeset.empty_text_field?(changeset, :email)
    end

    test "creation with data" do
      assert changeset = User.default_changeset(%User{email: "marick@exampler.com"})
      assert Changeset.has_data_for?(changeset, :email)
    end
  end

  @display_name "Display Name"
  @email "email@email.com"
  @auth_id "authid"
  # Note: the values in the permission list are the opposite of the defaults,
  # so that they are incorporated in the changes.
  @permission_list %{"view_reservations" => "false",
                     "make_reservations" => "true",
                     "manage_animals" => "true",
                     "manage_and_create_users" => "true"}

  describe "creation validations" do
    setup do
      params = %{"display_name" => @display_name,
                 "email" => @email,
                 "auth_id" => @auth_id,
                 "permission_list" => @permission_list,
                }
      [typical: params]
    end
    
    test "usual case", %{typical: typical} do
      changeset = User.create_changeset(typical)

      assert changeset.valid?
      assert changeset.errors == []

      user_changes = changeset.changes
      assert user_changes.display_name == @display_name
      assert user_changes.email == @email
      assert user_changes.auth_id == @auth_id

      assert user_changes.permission_list.action == :insert
      permission_changes = user_changes.permission_list.changes
      assert permission_changes.view_reservations == false
      assert permission_changes.make_reservations == true
      assert permission_changes.manage_animals == true
      assert permission_changes.manage_and_create_users == true
    end

    test "other fields are filtered out", %{typical: typical} do
      atypical = %{"id" => "3343", "active" => "false", "password_token" => "foo"}

      changeset = User.create_changeset(Map.merge(typical, atypical))

      assert changeset.valid? # filtered out
      assert changeset.errors == []
      
      refute changeset.changes[:id]
      refute changeset.changes[:active]
      refute changeset.changes[:password_token]
    end

    test "selected error checks", %{typical: typical} do
      atypical =
        typical
        |> Map.put("auth_id", "    ")
        |> Map.put("display_name", "a")
        |> Map.delete("email")

      errors = User.create_changeset(atypical) |> errors_on
      assert "can't be blank" in errors.auth_id
      assert "can't be blank" in errors.email
      assert "should be at least 2 character(s)" in errors.display_name
    end
  end
end
  
