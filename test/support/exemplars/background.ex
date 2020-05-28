defmodule Crit.Exemplars.Background do
  use ExUnit.CaseTemplate
  use Crit.TestConstants
  alias Crit.Exemplars.ReservationFocused
  alias Crit.Setup.ProcedureApi
  import DeepMerge
  alias Crit.Factory
  alias Ecto.Datespan

  #-----------------------------------------------------

  def background(species_id) do
    %{species_id: species_id}
  end

  def procedure_frequency(data, calculation_name) do
    schema = :procedure_frequency
    
    addition = Factory.sql_insert!(schema,
      name: calculation_name <> " procedure frequency",
      calculation_name: calculation_name)

    deep_merge(data, %{schema => %{calculation_name => addition}})
  end

  def procedure(data, procedure_name, opts \\ []) do 
    opts = Enum.into(opts, %{frequency: "unlimited"})

    schema = :procedure
    frequency = data.procedure_frequency[opts.frequency]
    species_id = data.species_id

    %{id: id} = Factory.sql_insert!(schema,
      name: procedure_name,
      species_id: species_id,
      frequency_id: frequency.id)
    addition = ProcedureApi.one_by_id(id, @institution, preload: [:frequency])
    
    deep_merge(data, %{schema => %{procedure_name => addition}})
  end


  def procedures(data, descriptors) do
    Enum.reduce(descriptors, data, fn {key, opts}, acc ->
      apply &procedure/3, [acc, key, opts]
    end)
  end

  def animal(data, animal_name, opts \\ []) do
    opts =
      Enum.into(opts, %{
            available_on: @earliest_date,
            species_id: data.species_id})
    
    schema = :animal

    in_service_date = opts.available_on
    span = Datespan.customary(in_service_date, @latest_date)

    addition = Factory.sql_insert!(schema,
      name: animal_name,
      span: span,
      species_id: opts.species_id)

    deep_merge(data, %{schema => %{animal_name => addition}})
  end

  def reservation_for(data, purpose, animal_names, procedure_names, opts \\ []) do
    schema = :reservation
    species_id = data.species_id
    
    addition =
      ReservationFocused.reserved!(species_id, animal_names, procedure_names, opts)

    deep_merge(data, %{schema => %{purpose => addition}})
  end

  #-----------------------------------------------------

  
end
