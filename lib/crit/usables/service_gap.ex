defmodule Crit.Usables.HiddenSchemas.ServiceGap do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Datespan

  schema "service_gaps" do
    field :animal_id, :id
    field :span, Datespan
    field :reason, :string

    field :start_date, :date
    field :end_date, :date
  end


  def changeset(gap, attrs) do
    gap
    |> cast(attrs, [:span, :reason])
    |> put_start_date
    |> put_end_date
  end

  def put_start_date(changeset) do
    value = get_field(changeset, :span) |> Datespan.start_string
    put_change(changeset, :start_datestring, value)
  end
  
  def put_end_date(changeset) do
    value = get_field(changeset, :span) |> Datespan.end_string
    put_change(changeset, :end_datestring, value)
  end
end
