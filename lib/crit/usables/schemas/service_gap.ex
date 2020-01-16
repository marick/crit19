defmodule Crit.Usables.Schemas.ServiceGap do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Datespan
  use Crit.Errors
  alias Crit.FieldConverters.ToSpan
  alias Crit.FieldConverters.FromSpan

  schema "service_gaps" do
    field :animal_id, :id
    field :span, Datespan
    field :reason, :string

    field :institution, :string, virtual: true 
    field :in_service_datestring, :string, virtual: true
    field :out_of_service_datestring, :string, virtual: true
    field :delete, :boolean, default: false, virtual: true
  end

  @required_for_insertion [:reason]
  @usable @required_for_insertion ++ [:animal_id, :delete]

  def empty_sentinels,
    do: ["in_service_datestring", "out_of_service_datestring", "reason"]
  
  def changeset(gap, attrs) do
    gap
    |> cast(attrs, @usable)
    |> validate_required(@required_for_insertion)
    |> ToSpan.synthesize(attrs)
    |> mark_deletion
  end

  def put_updatable_fields(%__MODULE__{} = gap, institution) do
    gap
    |> FromSpan.expand
    |> Map.put(:institution, institution)
  end


  defp mark_deletion(changeset) do
    case fetch_field!(changeset, :delete) do
      true ->
        %{changeset | action: :delete}
      _ ->
        changeset
    end
  end
end
