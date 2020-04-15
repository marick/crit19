defmodule Crit.FieldConverters.ToSpan do
  use Ecto.Schema
  use Crit.Global.Constants
  use Crit.Errors
  alias Ecto.Changeset
  alias Ecto.Datespan
  alias Crit.Setup.InstitutionApi

  # Assumes this partial schema. Fields are constant because they come from
  # the domain.
  
  # field :in_service_datestring, :string
  # field :out_of_service_datestring, :string
  # field :institution, :string
  
  # field :span, Datespan

  # Note: it's an assumed precondition that the first three fields
  # exist in either the changeset's `data` or its `changes`. That is,
  # they have already been `cast` and `validate_required`.

  @required [:in_service_datestring, :out_of_service_datestring, :institution]

  # Having two versions of the function is clearer for testing.
  # Non-testing clients will use this one.
  def synthesize(struct_or_changeset, attrs) do
    struct_or_changeset
    |> Changeset.cast(attrs, @required)
    |> Changeset.validate_required(@required)
    |> synthesize
  end

  def synthesize(changeset) do
    changeset
    |> assume_infinite_up
    |> apply_out_of_service_date
    |> check_date_compatibility
  end

  defp assume_infinite_up(changeset) do
    case parse_date(changeset, :in_service_datestring) do
      {:ok, @never} ->
        msg = ~S{"must be a date or "today"}
        safely_add_error(changeset, :in_service_datestring, msg)
      {:ok, in_service} ->
        put_span(changeset, Datespan.inclusive_up(in_service))
      {:error, _tag} ->
        safely_add_error(changeset, :in_service_datestring, "is invalid")
    end
  end

  defp apply_out_of_service_date(changeset) do
    case parse_date(changeset, :out_of_service_datestring) do
      {:ok, @never} ->
        changeset # this is what the first step assumed
      {:ok, out_of_service} ->
        case Changeset.fetch_field!(changeset, :span) do
          nil ->
            changeset  # This means first step failed.
          tentative_span -> 
            put_span(changeset, Datespan.put_last(tentative_span, out_of_service))
        end
      {:error, _tag} ->
        safely_add_error(changeset, :out_of_service_datestring, "is invalid")
    end
  end

  # This is somewhat complicated. You might think that you could guard this 
  # function with:
  #  
  #     defp check_date_compatibility(%{valid?: false} = changeset), do: changeset
  #
  # That doesn't work if nested changesets are validated before this
  # changeset's `:span` is calculated. If any of those prove invalid,
  # this changeset is marked as also invalid, which leads to no date
  # misorder message until the user fixes the error in the nested form
  # and resubmits. That would be rude, so we check if there's any `span`
  # *to* check.
  defp check_date_compatibility(changeset) do
    span = Changeset.fetch_field!(changeset, :span)
    cond do
      span == nil ->
        changeset
      not Datespan.is_customary?(span) ->
        changeset
      Date.compare(span.first, span.last) == :lt ->
        changeset
      :else ->
        safely_add_error(changeset, :out_of_service_datestring, @date_misorder_message)
    end
  end

  defp put_span(changeset, span),
    do: Changeset.put_change(changeset, :span, span)

  # Delete span so as to prevent invalid value from being visible outside the module.
  defp safely_add_error(changeset, field, message) do
    changeset
    |> Changeset.add_error(field, message)
    |> Changeset.delete_change(:span)
  end

  defp parse_date(changeset, field) do
    datestring = Changeset.fetch_field!(changeset, field)
    
    case datestring do
      nil ->
        {:error, :irrelevant}
      @never ->
        {:ok, @never}
      @today ->
        institution = Changeset.fetch_field!(changeset, :institution)
        {:ok, InstitutionApi.today!(institution)}
      _ -> 
        Date.from_iso8601(datestring)
    end
  end
end  
