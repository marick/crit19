defmodule Crit.History.Audit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_log" do
    field :version, :integer, default: 1
    field :user_responsible, :id
    field :event, :string
    field :data, :map

    timestamps(updated_at: false)
  end

  @fields [:version, :user_responsible, :event, :data]

  def changeset(audit, attrs) do
    audit
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
