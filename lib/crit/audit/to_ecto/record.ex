defmodule Crit.Audit.ToEcto.Record do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_log" do
    field :event_owner_id, :id
    field :version, :integer, default: 1
    field :event, :string
    field :data, :map

    timestamps(updated_at: false)
  end

  @fields [:version, :event, :data, :event_owner_id]

  def changeset(audit, attrs) do
    audit
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
