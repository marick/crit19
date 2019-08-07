defmodule Crit.Clients do
  alias Crit.Repo

  def all(queryable, opts \\ []),
    do: Repo.all(queryable, add_prefix(opts))
  
  def insert(struct_or_changeset, opts \\ []),
    do: Repo.insert(struct_or_changeset, add_prefix(opts))

  defp add_prefix(opts), do: opts ++ [prefix: "clients"]
end
