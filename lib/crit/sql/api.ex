defmodule Crit.Sql.Api do

@callback insert(
  struct_or_changeset :: Ecto.Schema.t() | Ecto.Changeset.t(),
  opts :: Keyword.t()
) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}

end
