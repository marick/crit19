defmodule Crit.Global.Institution do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Global.TimeSlot

  @schema_prefix "global"
  
  schema "institutions" do
    field :display_name, :string
    field :short_name, :string
    field :prefix, :string
    field :repo, :string
    field :timezone, :string
    has_many :time_slots, TimeSlot

    timestamps()
  end

  @doc false
  def changeset(institution, attrs) do
    institution
    |> cast(attrs, [:display_name, :short_name, :prefix, :repo])
    |> validate_required([:display_name, :short_name, :prefix, :repo])
  end
end
