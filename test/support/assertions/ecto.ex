defmodule Crit.Assertions.Ecto do
  import ExUnit.Assertions
  import Crit.Assertions.Defchain

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
      
end
