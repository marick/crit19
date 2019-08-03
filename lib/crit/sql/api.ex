defmodule Crit.Sql.Api do

@callback insert(
  struct_or_changeset :: Ecto.Schema.t() | Ecto.Changeset.t(),
  opts :: Keyword.t()
) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}

@callback one(queryable :: Ecto.Queryable.t(), opts :: Keyword.t()) ::
  Ecto.Schema.t() | nil

@callback get_by(
  queryable :: Ecto.Queryable.t(),
  clauses :: Keyword.t() | map(),
  opts :: Keyword.t()
) :: Ecto.Schema.t() | nil
  
end
