defmodule CritBiz.ViewModels.FieldValidators do
  use Crit.Global.Constants
  use Crit.Errors
  import Ecto.Changeset
  alias Ecto.ChangesetX
  alias Crit.Setup.InstitutionApi
  alias Pile.Namelist

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
  def cast_sublist(changeset, field, validator) do
    changesets = 
      get_change(changeset, field, [])
      |> validator.()

    validity = Enum.all?(changesets, &(&1.valid?))

    changeset
    |> put_change(field, changesets)
    |> Map.put(:valid?, validity)
  end


  def namelist(changeset, field) do
    string = get_change(changeset, field, "")
    case Namelist.to_list(string) do
      [] -> 
        add_error(changeset, field, @no_valid_names_message)
      list ->
        if EnumX.has_duplicates?(list) do
          add_error(changeset, field, @duplicate_name)
        else
          changeset
        end
    end
  end
  
end
