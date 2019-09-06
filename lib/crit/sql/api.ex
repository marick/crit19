defmodule Crit.Sql.Api do

@callback all(
  queryable :: Ecto.Queryable.t(),
  opts :: Keyword.t(),
  key :: String.t()
) :: [Ecto.Schema.t()]

@callback delete_all(
  queryable :: Ecto.Queryable.t(),
  opts :: Keyword.t(),
  key :: String.t()
) :: {integer(), nil | [term()]}

@callback exists?(
  queryable :: Ecto.Queryable.t(),
  opts :: Keyword.t(),
  key :: String.t()
) :: boolean()

@callback get(
  queryable :: Ecto.Queryable.t(),
  id :: term(),
  opts :: Keyword.t(),
  key :: String.t()
) ::
  Ecto.Schema.t() | nil
  
@callback get!(
  queryable :: Ecto.Queryable.t(),
  id :: term(),
  opts :: Keyword.t(),
  key :: String.t()
) ::
  Ecto.Schema.t()
  
@callback get_by(
  queryable :: Ecto.Queryable.t(),
  clauses :: Keyword.t() | map(),
  opts :: Keyword.t(),
  key :: String.t()
) :: Ecto.Schema.t() | nil

@callback insert(
  struct_or_changeset :: Ecto.Schema.t() | Ecto.Changeset.t(),
  opts :: Keyword.t(),
  key :: String.t()
) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}

@callback insert!(
  struct_or_changeset :: Ecto.Schema.t() | Ecto.Changeset.t(),
  opts :: Keyword.t(),
  key :: String.t()
) :: Ecto.Schema.t()

@callback one(
  queryable :: Ecto.Queryable.t(),
  opts :: Keyword.t(),
  key :: String.t()
) ::
  Ecto.Schema.t() | nil

@callback update(
  changeset :: Ecto.Changeset.t(),
  opts :: Keyword.t(),
  key :: String.t()
) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}


end
