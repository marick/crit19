defmodule Crit.Schemas.Institution do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Repo

  @schema_prefix "global"
  
  schema "institutions" do
    field :display_name, :string
    field :short_name, :string
    field :prefix, :string
    field :repo, :string
    field :timezone, :string

    timestamps()
  end

  @doc false
  def changeset(institution, attrs) do
    institution
    |> cast(attrs, [:display_name, :short_name, :prefix, :repo])
    |> validate_required([:display_name, :short_name, :prefix, :repo])
  end

  def all do
    Repo.all(__MODULE__)
  end
  
end
