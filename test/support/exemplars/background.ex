defmodule Crit.Exemplars.Background do
  use ExUnit.CaseTemplate
  use Crit.TestConstants
  alias Crit.Exemplars.ReservationFocused
  import DeepMerge
  alias Crit.Factory
  alias Ecto.Datespan
  alias Crit.Setup.Schemas.{Animal, Procedure}
  alias Crit.Setup.{AnimalApi, ProcedureApi}

  @valid MapSet.new([:procedure_frequency, :procedure, :animal,
                     :reservation])

  #-----------------------------------------------------------------------------
  def background(species_id \\ @bovine_id) do
    %{species_id: species_id}
  end

  @doc """
  Sometimes associations can be added on after a structure is created.
  This replaces a partially loaded structure with one that has
  all its possible preloads loaded.
  """
  def load_completely(data) do 
    Enum.reduce(@valid, data, fn schema, acc ->
      load_completely(acc, schema)
    end)
  end

  @doc """
  Make the atom-ized name a key on the map. This allows:

       background = ...
         |> procedure("one_procedure")
         |> shorthand

       ...
       background.one_procedure 
  """
       
  def shorthand(data) do 
    Enum.reduce(@valid, data, fn schema, acc ->
      shorthand(acc, data[schema])
    end)
  end

  #-----------------------------------------------------------------------------
  

  def procedure_frequency(data, calculation_name) do
    schema = :procedure_frequency
    
    addition = Factory.sql_insert!(schema,
      name: calculation_name <> " procedure frequency",
      calculation_name: calculation_name)

    put(data, schema, calculation_name, addition)
  end

  def procedure(data, procedure_name, opts \\ []) do 
    opts = Enum.into(opts, %{frequency: "unlimited"})

    frequency = lazy_frequency(data, opts.frequency)   # Create as needed
    species_id = data.species_id

    %{id: id} = Factory.sql_insert!(:procedure,
      name: procedure_name,
      species_id: species_id,
      frequency_id: frequency.id)
    addition = ProcedureApi.one_by_id(id, @institution, preload: [:frequency])
    put(data, :procedure, procedure_name, addition)
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

    in_service_date = opts.available_on
    span = Datespan.customary(in_service_date, @latest_date)

    addition = Factory.sql_insert!(:animal,
      name: animal_name,
      span: span,
      species_id: opts.species_id)

    put(data, :animal, animal_name, addition)
  end

  def reservation_for(data, purpose, animal_names, procedure_names, opts \\ []) do
    schema = :reservation
    species_id = data.species_id
    
    addition =
      ReservationFocused.reserved!(species_id, animal_names, procedure_names, opts)

    put(data, schema, purpose, addition)
  end

  def service_gap_for(data, animal_name, opts \\ []) do
    opts = Enum.into(opts, %{
          starting: @earliest_date, ending: @latest_date,
          name: Factory.name("service_gap")})
    animal_id = id(data, :animal, animal_name)
    span = Datespan.customary(opts.starting, opts.ending)

    addition =
      Factory.sql_insert!(:service_gap, [animal_id: animal_id, span: span],
        @institution)
    put(data, :service_gap, opts.name, addition)
  end

  #-----------------------------------------------------

  @valid MapSet.new([:procedure_frequency, :procedure, :animal,
                     :reservation])

  def valid_schema?(key), do: MapSet.member?(@valid, key)

  def put(data, schema, name, value) do
    deep_merge(data, %{schema => %{name => value}})
  end

  defp get(data, schema, name) do
    assert valid_schema?(schema)
    with(
      category <- data[schema],
      value <- category[name]
    ) do
      value
    end
  end
  
  defp lazy_get(data, schema, name, putter) do
    get(data, schema, name)
    || putter.(data) |> lazy_get(schema, name, putter)
  end

  def id(data, schema, name), do: get(data, schema, name).id

  def ids(data, schema, names) do
    for name <- names, do: id(data, schema, name)
  end

  defp lazy_frequency(data, calculation_name) do
    lazy_get(data, :procedure_frequency, calculation_name,
      &(procedure_frequency(&1, calculation_name)))
  end

  # ----------------------------------------------------------------------------

  defp load_completely(data, :procedure),
    do: load_completely(data, :procedure, ProcedureApi, Procedure)
  defp load_completely(data, :animal),
    do: load_completely(data, :animal, AnimalApi, Animal)
  defp load_completely(data, _), do: data

  defp load_completely(data, schema, api, module) do
    Enum.reduce(Map.keys(data[schema]), data, fn name, acc ->
      new = 
        acc
        |> id(schema, name)
        |> api.one_by_id(@institution, preload: module.preloads())

      put(acc, schema, name, new)
    end)
  end

  # ----------------------------------------------------------------------------
  defp shorthand(data, nil), do: data
  defp shorthand(data, schema_map) do 
    Enum.reduce(schema_map, data, fn {name, value}, acc ->
      name_atom = name |> String.downcase |> String.to_atom
      refute Map.has_key?(acc, name_atom)
      Map.put(acc, name_atom, value)
    end)
  end
end
