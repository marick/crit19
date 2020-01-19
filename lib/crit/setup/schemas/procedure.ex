defmodule Crit.Setup.Schemas.Procedure do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Ecto.TrimmedString
  alias Crit.Sql

  schema "procedures" do
    field :name, TrimmedString

    timestamps()
  end

  @required [:name]

  def changeset(procedure, attrs) do
    procedure
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> unique_constraint(:name)
  end

  def insert(attrs, institution) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Sql.insert(institution)
  end
end
