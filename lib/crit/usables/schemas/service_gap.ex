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

  @required_for_insertion [:reason, :in_service_datestring, :out_of_service_datestring, :institution]
  @usable @required_for_insertion ++ [:animal_id, :delete]
  
  def changeset(gap, attrs) do
    gap
    |> cast(attrs, @usable)
    |> validate_required(@required_for_insertion)
    |> ToSpan.synthesize
    |> mark_deletion
  end

  def put_updatable_fields(%__MODULE__{} = gap),
    do: FromSpan.expand(gap)

  defp validate_order(%{valid?: false} = changeset), do: changeset
  defp validate_order(changeset) do
    {should_be_earlier, should_be_later} = dates(changeset)
    case Date.compare(should_be_earlier, should_be_later) do
      :lt ->
        changeset
      _ ->
        note_misorder(changeset, :out_of_service_datestring)
    end
  end

  defp note_misorder(changeset, field) do
    add_error(changeset, field, @date_misorder_message)
  end
  

  # This insulates tests from knowing the data representation
  def span(in_service, out_of_service),
    do: Datespan.customary(in_service, out_of_service)

  defp put_span(%{valid?: false} = changeset), do: changeset
  defp put_span(changeset) do
    {in_service, out_of_service} = dates(changeset)
    put_change(changeset, :span, span(in_service, out_of_service))
  end

  defp mark_deletion(changeset) do
    case fetch_field!(changeset, :delete) do
      true ->
        %{changeset | action: :delete}
      _ ->
        changeset
    end
  end


  defp dates(changeset),
    do: {in_service_datestring(changeset), out_of_service_datestring(changeset)}
  defp in_service_datestring(changeset),
    do: fetch_field!(changeset, :in_service_datestring)
  defp out_of_service_datestring(changeset),
    do: fetch_field!(changeset, :out_of_service_datestring)
end
