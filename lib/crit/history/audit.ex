defmodule Crit.History.Audit do
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

  defmodule Query do
    import Ecto.Query
    alias Crit.History.Audit

    def n_most_recent(n, event) do
      from a in Audit,
        where: a.event == ^event,
        order_by: [desc: a.inserted_at],
        limit: ^n
    end
      
  end
end
