defmodule Crit.Usables.HiddenSchemas.ServiceGap do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Datespan
  alias Crit.Usables.FieldConverters.ToDate

  schema "service_gaps" do
    field :animal_id, :id
    field :span, Datespan
    field :reason, :string

    field :in_service_date, :date, virtual: true
    field :out_of_service_date, :date, virtual: true
  end
  def changeset(gap, attrs) do
    gap
    |> cast(attrs, [:animal_id, :reason, :in_service_date, :out_of_service_date])
    |> validate_required([:reason, :in_service_date, :out_of_service_date])
    |> validate_order
    |> put_span
  end


  def validate_order(%{valid?: false} = changeset), do: changeset
  def validate_order(changeset) do
    {should_be_earlier, should_be_later} = dates(changeset)
    case Date.compare(should_be_earlier, should_be_later) do
      :lt ->
        changeset
      _ ->
        ToDate.note_misorder(changeset, :out_of_service_date)
    end
  end

  def put_span(%{valid?: false} = changeset), do: changeset
  def put_span(changeset) do
    {in_service, out_of_service} = dates(changeset)
    put_change(changeset, :span, Datespan.customary(in_service, out_of_service))
  end 


  def dates(changeset),
    do: {in_service_date(changeset), out_of_service_date(changeset)}
  def in_service_date(changeset),
    do: fetch_field!(changeset, :in_service_date)
  def out_of_service_date(changeset),
    do: fetch_field!(changeset, :out_of_service_date)

    
  
end
