defmodule Crit.FieldConverters.ToSpan do
  use Ecto.Schema
  use Crit.Global.Constants
  use Crit.Errors
  import Ecto.Changeset
  alias Pile.TimeHelper
  alias Ecto.Datespan
  alias Crit.Global
  import Pile.Interface

  # Assumes this partial schema. Fields are constant because they come from
  # the domain.
  
  # field :in_service_datestring, :string
  # field :out_of_service_datestring, :string
  # field :institution, :string
  
  # field :span, Datespan

  # Note: it's an assumed precondition that the first three fields
  # exist in either the changeset's `data` or its `changes`. That is,
  # they have already been `cast` and `validate_required`. 

  def synthesize(changeset) do
    assume_infinite_up(changeset)
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
        tentative_span = fetch_field!(changeset, :span)
        put_span(
          changeset,
          Datespan.put_last(tentative_span, out_of_service))
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
  # and resubmits. That would be rude, so...
  defp check_date_compatibility(changeset) do
    span = fetch_field!(changeset, :span)
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

  defp put_span(changeset, span), do: put_change(changeset, :span, span)

  # Delete span so as to prevent invalid value from being visible outside the module.
  defp safely_add_error(changeset, field, message) do
    changeset
    |> add_error(field, message)
    |> delete_change(:span)
  end

  defp parse_date(changeset, field) do
    datestring = fetch_field!(changeset, field)
    
    case datestring do
      @never ->
        {:ok, @never}
      @today ->
        institution = fetch_field!(changeset, :institution)
        timezone = some(Global).timezone(institution)
        {:ok, TimeHelper.today_date(timezone)}
      _ -> 
        Date.from_iso8601(datestring)
    end
  end
end  
