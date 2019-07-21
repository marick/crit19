defmodule Crit.History.Audit do
  use Ecto.Schema
  import Ecto.Changeset

  schema "audit_log" do
    belongs_to :event_owner, Crit.Users.User
    field :version, :integer, default: 1
    field :event, :string
    field :data, :map

    timestamps(updated_at: false)
  end

  @fields [:version, :event_owner, :event, :data]

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
