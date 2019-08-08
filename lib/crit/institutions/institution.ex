defmodule Crit.Institutions.Institution do
  use Ecto.Schema
  import Ecto.Changeset

  @schema_prefix "clients"
  
  schema "institutions" do
    field :display_name, :string
    field :short_name, :string
    field :prefix, :string
    field :repo, :string

    timestamps()
  end

  @doc false
  def changeset(institution, attrs) do
    institution
    |> cast(attrs, [:display_name, :short_name, :prefix, :repo])
    |> validate_required([:display_name, :short_name, :prefix, :repo])
  end
end
