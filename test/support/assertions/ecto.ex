defmodule Crit.Assertions.Ecto do
  import ExUnit.Assertions
  import Crit.Assertions.Defchain
  import FlowAssertions.MapA

  defchain assert_assoc_loaded(struct, keys) when is_list(keys) do
    for k <- keys, do: assert_assoc_loaded(struct, k)
  end

  defchain assert_assoc_loaded(struct, key),
    do: assert assoc_loaded?(struct, key)

  defchain refute_assoc_loaded(struct, keys) when is_list(keys) do
    for k <- keys, do: refute_assoc_loaded(struct, k)
  end

  defchain refute_assoc_loaded(struct, key),
    do: refute assoc_loaded?(struct, key)
  
  defp assoc_loaded?(struct, key) do
    not match?(%Ecto.Association.NotLoaded{}, Map.get(struct, key))
  end

  defchain assert_schema(value, module_name) do
    assert value.__meta__.schema == module_name
  end

  defchain assert_schema_copy(new, original, [ignoring: extras]) do
    ignoring = extras ++ [:inserted_at, :updated_at, :__meta__]
    assert_same_map(new, original, ignoring: ignoring)
  end
end
