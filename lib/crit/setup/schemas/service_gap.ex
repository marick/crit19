defmodule Crit.Setup.Schemas.ServiceGap do
  use Ecto.Schema
  import Ecto.Changeset
  use Crit.Errors
  alias Ecto.Datespan
  import Ecto.Query
  import Ecto.Datespan
  alias Crit.Sql
  alias Crit.Sql.CommonQuery
  
  schema "service_gaps" do
    field :animal_id, :id
    field :span, Datespan
    field :reason, :string
  end

  def fields, do: __schema__(:fields)

  # :id and :animal_id are not needed for creation. 
  def required, do: ListX.delete(fields(), [:id, :animal_id])

  def changeset(gap, attrs) do
    gap
    |> cast(attrs, fields())
    |> validate_required(required())
  end

  # ----------------------------------------------------------------------------
  def narrow_animal_query_by(query, %Date{} = date) do
    from a in query,
      join: sg in __MODULE__, on: sg.animal_id == a.id,
      where: contains_point_fragment(sg.span, ^date)
  end
  
  def unavailable_by(animal_query, %Date{} = date, institution) do
    animal_query
    |> narrow_animal_query_by(date)
    |> CommonQuery.ordered_by_name
    |> Sql.all(institution)
  end
end
