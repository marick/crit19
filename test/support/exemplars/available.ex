defmodule Crit.Exemplars.Available do
  @moduledoc """
  This creates structures that are "fit for use". For example, an animal
  created here will have been placed into service today or earlier and will be
  taken out of service later than today.
  """

  # Note: moving forward, @date_1 will be the date of availability, unless
  # otherwise specified.
  
  use ExUnit.CaseTemplate
  use Crit.TestConstants
  use Crit.TestConstants
  alias Crit.Factory
  alias Crit.Setup.AnimalApi
  alias Crit.Exemplars
  alias Crit.Factory
  alias Ecto.Datespan

  def animal_ids(opts \\ []) do
    params = Enum.into(opts,
      %{names: Factory.unique_names_string(),
        species_id: to_string(Factory.some_species_id()),
        in_service_datestring: Exemplars.Date.iso_today_or_earlier(), 
        out_of_service_datestring: Exemplars.Date.iso_later_than_today(),
        institution: @institution,
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
        nil -> Keyword.put(opts, :names, Faker.Cat.name())
        name -> Keyword.put(opts, :names, name)
      end

    [id] = animal_ids(true_opts)
    id
  end

  defp insert_species(name, span, species_id) do 
    Factory.sql_insert!(:animal ,
      [name: name, species_id: species_id,
       span: span],
      @institution)
    end

  def bovine(name),
    do: bovine(name, @date_1)
  def bovine(name, %Date{} = in_service_date), 
    do: bovine(name, Datespan.inclusive_up(in_service_date))
  def bovine(name, %Datespan{} = span), 
    do: insert_species(name, span, @bovine_id)

  def equine(name),
    do: equine(name, @date_1)
  def equine(name, %Date{} = in_service_date), 
    do: equine(name, Datespan.inclusive_up(in_service_date))
  def equine(name, %Datespan{} = span), 
    do: insert_species(name, span, @equine_id)

    

  def bovine_procedure(name), do: procedure(name, @bovine_id)
    
  def procedure(name, species_id) do
    Factory.sql_insert!(:procedure,
      [name: name, species_id: species_id],
      @institution)
  end
end
