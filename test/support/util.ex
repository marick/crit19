defmodule Crit.Test.Util do
  use ExUnit.CaseTemplate
  alias Crit.Factory

  # We don't want Ex Machina generating a password.
  def string_params_for_new_user(attrs \\ []) do
    original = Factory.string_params_for(:user, attrs)
    permission_list = Factory.string_params_for(:permission_list)

    Map.put(original, "permission_list", permission_list)
  end



  # Avoid fields that don't matter for correctness and tend to
  # produce spurious miscomparisons
  # def masked(%User{} = user), do: %{user | password: nil, password_token: nil}


  # def assert_close_enough(x, y) when is_list(x) and is_list(y),
  #   do: Enum.map(x, &masked/1) == Enum.map(y, &masked/1)

  # def assert_close_enough(x, y),
  #   do: masked(x) == masked(y)
  
  # def assert_same_values(one_maplike, other_maplike, keys) do
  #   one_map = string_keys(one_maplike)
  #   other_map = string_keys(other_maplike)
  #   for k <- stringify(keys) do
  #     assert Map.has_key?(one_map, k)
  #     assert Map.has_key?(other_map, k)
  #     assert one_map[k] == other_map[k]
  #   end
  # end

  # def assert_has_exactly_these_keys(keylist, keys) do
  #   assert MapSet.new(Keyword.keys(keylist)) == MapSet.new(keys)
  # end

  # def string_keys(maplike) do
  #   keys = Map.keys(maplike)
  #   Enum.reduce(keys, %{},
  #     fn (k, acc) ->
  #       Map.put(acc, stringify(k), Map.get(maplike, k))
  #     end)
  # end

  # def stringify(x) when is_atom(x), do: Atom.to_string(x)
  # def stringify(x) when is_binary(x), do: x
  # def stringify(x) when is_list(x), do: Enum.map(x, &stringify/1)
end
