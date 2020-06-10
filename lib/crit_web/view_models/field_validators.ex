defmodule CritWeb.ViewModels.FieldValidators do
  use Crit.Global.Constants
  use Crit.Errors
  import Ecto.Changeset
  alias Ecto.ChangesetX
  alias Crit.Setup.InstitutionApi

  def date_order(%{valid?: false} = changeset), do: changeset
  def date_order(changeset) do
    fields = [:in_service_datestring, :out_of_service_datestring]
    
    date_order_(changeset, ChangesetX.values(changeset, fields))
  end

  defp date_order_(changeset, [_, @never]), do: changeset
  
  defp date_order_(changeset, [@today, out_of_service]) do
    iso_today =
      changeset
      |> fetch_field!(:institution)
      |> InstitutionApi.today!
      |> Date.to_iso8601

    date_order_(changeset, [iso_today, out_of_service])
  end
  
  defp date_order_(changeset, [in_service, out_of_service]) do
    case in_service < out_of_service do  # Works: ISO8601
      true ->
        changeset
      false ->
        add_error(changeset, :out_of_service_datestring, @date_misorder_message)
    end
  end

  # This is tested through use. See, for example, ViewModels.Setup.Animal
  def cast_subarray(changeset, field, validator) do
    changesets = 
      get_change(changeset, field, [])
      |> Enum.map(validator)

    validity = Enum.all?(changesets, &(&1.valid?))

    changeset
    |> put_change(field, changesets)
    |> Map.put(:valid?, validity)
  end
end
