defmodule Crit.Schemas.Reservation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Timespan
  alias Crit.Schemas.Use

  # The date could be extracted from the `span`, but making it explicit
  # is more convenient for some uses.
  
  schema "reservations" do
    field :species_id, :id
    field :date, :date
    field :span, Timespan
    field :timeslot_id, :id
    field :responsible_person, :string
    has_many :uses, Use
    timestamps()
  end

  def associations, do: __schema__(:associations)

  @required [:span, :date, :species_id, :timeslot_id, :responsible_person]

  def changeset(reservation, attrs) do
    reservation
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> cast_assoc(:uses)
    |> foreign_key_constraint(:species_id)
  end


  defmodule Get do
    import Ecto.Query
    alias Crit.Sql
    alias Crit.Sql.CommonQuery
    alias Crit.Schemas.Reservation

    def one_by_id(id, institution, opts \\ []) do
      preloads = Keyword.get(opts, :preload, [])
      
      CommonQuery.start_by_id(Reservation, id)
      |> preload(^preloads)
      |> Sql.one(institution)
    end
  end
end
