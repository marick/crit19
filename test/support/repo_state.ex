defmodule Crit.RepoState do
  use ExUnit.CaseTemplate
  use Crit.TestConstants
  alias Crit.Exemplars.ReservationFocused
  alias Crit.Factory
  alias Ecto.Datespan
  alias Crit.Schemas.{Animal, Procedure}
  alias Pile.RepoBuilder, as: B

  @valid MapSet.new([:procedure_frequency, :procedure, :animal,
                     :reservation, :service_gap])

  #-----------------------------------------------------------------------------
  def empty_repo(species_id \\ @bovine_id) do
    %{species_id: species_id}
  end

  @doc """
  Sometimes associations can be added on after a structure is created.
  This replaces a partially loaded structure with one that has
  all its possible preloads loaded.
  """
  def load_completely(so_far) do 
    Enum.reduce(@valid, so_far, fn schema, acc ->
      load_completely(acc, schema)
    end)
  end

  @doc """
  Make the atom-ized name a key on the map. This allows:

       repo = ...
         |> procedure("one_procedure")
         |> shorthand

       ...
       repo.one_procedure 
  """
       
  def shorthand(so_far) do
    Enum.reduce(@valid, so_far, fn schema, acc ->
      shorthand_(acc, so_far[:__schemas__][schema])
    end)
  end

  #-----------------------------------------------------------------------------
  

  def procedure_frequency(so_far, calculation_name) do
    schema = :procedure_frequency
    
    addition = Factory.sql_insert!(schema,
      name: calculation_name <> " procedure frequency",
      calculation_name: calculation_name)

    B.Schema.put(so_far, schema, calculation_name, addition)
  end

  def procedure(so_far, procedure_name, opts \\ []) do
    B.Schema.create_if_needed(so_far, :procedure, procedure_name, fn ->
      opts = Enum.into(opts, %{frequency: "unlimited"})
        
      frequency = lazy_frequency(so_far, opts.frequency)   # Create as needed
      species_id = so_far.species_id

      Factory.sql_insert!(:procedure,
        name: procedure_name,
        species_id: species_id,
        frequency_id: frequency.id)
    end)
  end

  def procedures(so_far, names) do
    Enum.reduce(names, so_far, fn name, acc ->
      apply &procedure/3, [acc, name, []]
    end)
  end

  defp compute_span(%Date{} = earliest_date),
    do: Datespan.customary(earliest_date, @latest_date)
  defp compute_span(%Datespan{} = span),
    do: span

  def animal(so_far, animal_name, opts \\ []) do
    B.Schema.create_if_needed(so_far, :animal, animal_name, fn -> 
      opts =
        Enum.into(opts, %{
              available: @earliest_date,
              species_id: so_far.species_id})
      
      Factory.sql_insert!(:animal,
        name: animal_name,
        span: compute_span(opts.available),
        species_id: opts.species_id)
    end)
  end

  def animals(so_far, names) do
    Enum.reduce(names, so_far, fn name, acc ->
      apply &animal/3, [acc, name, []]
    end)
  end

  def reservation_for(so_far, animal_names, procedure_names, opts \\ []) do
    schema = :reservation
    species_id = so_far.species_id
    name = Factory.unique("reservation")    

    so_far =
      so_far 
      |> procedures(procedure_names)
      |> animals(animal_names)
    
    addition =
      ReservationFocused.reserved!(species_id, animal_names, procedure_names, opts)

    B.Schema.put(so_far, schema, name, addition)
  end

  def service_gap_for(so_far, animal_name, opts \\ []) do
    opts = Enum.into(opts, %{
          starting: @earliest_date, ending: @latest_date,
          reason: Factory.unique(:repo_state),
          name: Factory.unique(:service_gap)})
    animal_id = id(so_far, :animal, animal_name)
    span = Datespan.customary(opts.starting, opts.ending)

    B.Schema.create_if_needed(so_far, :service_gap, opts.name, fn ->
      details = [animal_id: animal_id, span: span, reason: opts.reason]
      Factory.sql_insert!(:service_gap, details, @institution)
    end)
  end

  #-----------------------------------------------------

  def valid_schema?(key), do: MapSet.member?(@valid, key)

  defp lazy_schema_get(so_far, schema, name, putter) do
    B.Schema.get(so_far, schema, name)
    || putter.(so_far) |> lazy_schema_get(schema, name, putter)
  end

  def id(so_far, schema, name), do: B.Schema.get(so_far, schema, name).id

  def ids(so_far, schema, names) do
    for name <- names, do: id(so_far, schema, name)
  end

  defp lazy_frequency(so_far, calculation_name) do
    lazy_schema_get(so_far, :procedure_frequency, calculation_name,
      &(procedure_frequency(&1, calculation_name)))
  end

  # ----------------------------------------------------------------------------

  defp load_completely(so_far, :procedure),
    do: load_completely(so_far, :procedure, Procedure.Get, Procedure)
  defp load_completely(so_far, :animal),
    do: load_completely(so_far, :animal, Animal.Get, Animal)
  defp load_completely(so_far, _), do: so_far

  defp load_completely(so_far, schema, api, module) do
    keys = Map.keys(so_far[:__schemas__][schema] || %{})

    Enum.reduce(keys, so_far, fn name, acc ->
      new = 
        acc
        |> id(schema, name)
        |> api.one_by_id(@institution, preload: module.associations())

      B.Schema.put(acc, schema, name, new)
    end)
  end

  # ----------------------------------------------------------------------------
  defp shorthand_(so_far, nil), do: so_far
  defp shorthand_(so_far, schema_map) do
    Enum.reduce(schema_map, so_far, fn {name, value}, acc ->
      name_atom = name |> String.downcase |> String.to_atom
      Map.put(acc, name_atom, value)
    end)
  end
end
