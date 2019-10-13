defmodule Crit.Exemplars.Available do
  @moduledoc """
  This creates structures that are "fit for use". For example, an animal
  created here will have been placed into service today or earlier and will be
  taken out of service later than today.
  """ 
  
  use ExUnit.CaseTemplate
  use Crit.Global.Default
  use Crit.Global.Constants
  alias Crit.Factory
  alias Crit.Usables.AnimalApi
  alias Crit.Exemplars
  alias Crit.Factory

  def animal_ids(opts \\ []) do
    params = Enum.into(opts,
      %{names: Factory.unique_names_string(),
        species_id: to_string(Factory.some_species_id()),
        start_date: Exemplars.Date.iso_today_or_earlier(), 
        end_date: Exemplars.Date.iso_later_than_today(),
      })
    {:ok, animals} =
      params
      |> MapX.convert_atom_keys_to_strings
      |> AnimalApi.create_animals(@institution)
    EnumX.ids(animals)
  end

  def animal_id(opts \\ []) do
    true_opts =
      case Keyword.get(opts, :name) do
        nil -> opts
        name -> Keyword.put(opts, :names, name)
      end
        
    [id] = animal_ids(true_opts)
    id
  end
end
