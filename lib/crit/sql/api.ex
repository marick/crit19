defmodule Crit.Sql.Api do

@callback insert(
  struct_or_changeset :: Ecto.Schema.t() | Ecto.Changeset.t(),
  opts :: Keyword.t(),
  key :: String.t()
) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}

@callback one(
  queryable :: Ecto.Queryable.t(),
  opts :: Keyword.t(),
  key :: String.t()
) ::
  Ecto.Schema.t() | nil

@callback get(
  queryable :: Ecto.Queryable.t(),
  id :: term(),
  opts :: Keyword.t(),
  key :: String.t()
) ::
  Ecto.Schema.t() | nil
  
@callback get_by(
  queryable :: Ecto.Queryable.t(),
  clauses :: Keyword.t() | map(),
  opts :: Keyword.t(),
  key :: String.t()
) :: Ecto.Schema.t() | nil

@callback update(
  changeset :: Ecto.Changeset.t(),
  opts :: Keyword.t(),
  key :: String.t()
) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}  
end
