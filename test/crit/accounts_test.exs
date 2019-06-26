defmodule Crit.AccountsTest do
  use Crit.DataCase

  alias Crit.Accounts
  alias Crit.Factory

  describe "users" do
    alias Crit.Accounts.User

    def saved_user(attrs \\ %{}) do
      {:ok, user} = Factory.build(:user, attrs) |> Repo.insert
      %{user | password: nil}
    end

    test "list_users/0 returns all users" do
      user = saved_user()
      assert Accounts.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = saved_user()
      assert Accounts.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      params = paramify(Factory.build(:user))
      assert {:ok, %User{} = user} = Accounts.create_user(params)
      assert_same_values(user, params, [:active, :email, :name])
      assert String.length(user.password_hash) > 10
    end

    test "create_user/1 with missing data returns error changeset" do
      assert {:error, changeset} = Accounts.create_user(%{})
      assert_has_exactly_these_keys(changeset.errors, [:email, :name, :password])
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, changeset} = Accounts.create_user(
        %{name: "a", email: "a@b", password: ""})
      assert_has_exactly_these_keys(changeset.errors, [:email, :name, :password])
    end

    # test "update_user/2 with valid data updates the user" do
    #   user = user_fixture()
    #   assert {:ok, %User{} = user} = Accounts.update_user(user, @update_attrs)
    #   assert user.active == false
    #   assert user.email == "some updated email"
    #   assert user.name == "some updated name"
    #   assert user.password != "some updated password"
    # end

    # test "update_user/2 with invalid data returns error changeset" do
    #   user = user_fixture()
    #   assert {:error, %Ecto.Changeset{}} = Accounts.update_user(user, @invalid_attrs)
    #   assert user == Accounts.get_user!(user.id)
    # end


    # test "change_user/1 returns a user changeset" do
    #   user = user_fixture()
    #   assert %Ecto.Changeset{} = Accounts.change_user(user)
    # end
  end

  # Not really needed, but let's not use atoms in any tests.
  def paramify(struct) do
    Map.from_struct(struct)
    |> Map.new(fn ({k, v}) -> {Atom.to_string(k), v} end)
  end

  defp assert_same_values(struct, string_keys, keys) do
    atom_keys = Map.from_struct(struct)
    for k <- keys do
      assert atom_keys[k] == string_keys[Atom.to_string(k)]
    end
  end
  
  defp assert_has_exactly_these_keys(keylist, keys) do
    assert MapSet.new(Keyword.keys(keylist)) == MapSet.new(keys)
  end
end
