defmodule Crit.AccountsTest do
  use Crit.DataCase

  alias Crit.Accounts
  alias Crit.Factory

  describe "users" do
    alias Crit.Accounts.User

    def saved_user(attrs \\ %{}) do
      {:ok, user} = Factory.build(:user, attrs) |> Repo.insert
      # attrs will have virtual field, but result structure will not.
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
      params = string_keys(Factory.build(:user))
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
        %{"name" => "a", "email" => "a@b", "password" => ""})
      assert_has_exactly_these_keys(changeset.errors, [:email, :name, :password])
    end

    test "create_user/1 prevents duplicate emails" do
      unique = "unique@unique.com"
      saved_user(email: unique)
      new_user_attrs = Factory.build(:user, email: unique) |> string_keys
      assert {:error, changeset} = Accounts.create_user(new_user_attrs)
      assert_has_exactly_these_keys(changeset.errors, [:email])
    end

    test "update_user/2 with valid non-password fields" do
      original = saved_user(%{name: "First name"})
      assert {:ok, updated} = Accounts.update_user(original, %{name: "Second name"})
      assert updated.name == "Second name"
      assert_same_values(original, updated, [:password_hash, :active, :email])
    end

    test "changeset/1 returns a user changeset" do
      # The changeset used for initial creation.
      assert changeset = Accounts.changeset(%User{})
      assert changeset.data == %User{}
      assert changeset.action == nil

      # The changeset used for updating.
      user = saved_user()
      assert changeset = Accounts.changeset(user)
      assert changeset.data == user
      assert changeset.action == nil
    end
  end

  defp assert_same_values(one_maplike, other_maplike, keys) do
    one_map = string_keys(one_maplike)
    other_map = string_keys(other_maplike)
    for k <- stringify(keys) do
      assert Map.has_key?(one_map, k)
      assert Map.has_key?(other_map, k)
      assert one_map[k] == other_map[k]
    end
  end

  defp string_keys(maplike) do
    keys = Map.keys(maplike)
    Enum.reduce(keys, %{},
      fn (k, acc) ->
        Map.put(acc, stringify(k), Map.get(maplike, k))
      end)
  end

  defp stringify(x) when is_atom(x), do: Atom.to_string(x)
  defp stringify(x) when is_binary(x), do: x
  defp stringify(x) when is_list(x), do: Enum.map(x, &stringify/1)
        
  
  defp assert_has_exactly_these_keys(keylist, keys) do
    assert MapSet.new(Keyword.keys(keylist)) == MapSet.new(keys)
  end
end
