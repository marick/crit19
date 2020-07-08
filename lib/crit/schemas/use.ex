defmodule Crit.Schemas.Use do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset
  alias Crit.Schemas.{Animal,Procedure}
  alias Crit.Schemas.Reservation
  alias Crit.Sql
  import Ecto.Timespan
  alias Ecto.Timespan
  alias Crit.Sql.CommonQuery

  schema "uses" do
    belongs_to :animal, Animal
    belongs_to :procedure, Procedure
    field :reservation_id, :id
  end

  @required [:animal_id, :procedure_id, :reservation_id]

  def changeset(a_use, attrs) do
    a_use
    |> cast(attrs, @required)
    |> foreign_key_constraint(:animal_id)
    |> foreign_key_constraint(:procedure_id)
    |> foreign_key_constraint(:reservation_id)
  end

  def cross_product(animal_ids, procedure_ids) do
    for a <- animal_ids, p <- procedure_ids do
      %{animal_id: a, procedure_id: p}
    end
  end

  def uses(reservation_id, institution) do
    (from u in __MODULE__, where: u.reservation_id == ^reservation_id)
    |> Sql.all(institution)
  end

  def all_used(reservation_id, institution) do 
    uses = uses(reservation_id, institution)
    animal_ids = Enum.map(uses, &(&1.animal_id))
    procedure_ids = Enum.map(uses, &(&1.procedure_id))

    animals =
      (from a in Animal, where: a.id in ^animal_ids, order_by: a.name)
      |> Sql.all(institution)

    procedures =
      (from p in Procedure, where: p.id in ^procedure_ids, order_by: p.name)
      |> Sql.all(institution)

    {animals, procedures}
  end

  def narrow_animal_query_by(query, %Ecto.Timespan{} = span) do
    {:ok, range} = Timespan.dump(span)
    
    from a in query,
      join: u in __MODULE__, on: u.animal_id == a.id,
      join: r in Reservation, on: u.reservation_id == r.id,
      where: overlaps_fragment(r.span, ^range)
  end

  def unavailable_by(animal_query, %Ecto.Timespan{} = span, institution) do
    animal_query
    |> narrow_animal_query_by(span)
    |> CommonQuery.ordered_by_name
    |> Sql.all(institution)
  end
end
