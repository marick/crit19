defmodule Crit.RepoState do
  use ExUnit.CaseTemplate
  use Crit.TestConstants
  alias Crit.Exemplars.ReservationFocused
  alias Crit.Factory
  alias Ecto.Datespan
  alias Crit.Schemas.{Animal, Procedure}
  alias EctoTestDataBuilder, as: B

  #----- Initial values ------------------------------------------------------
  def empty_repo(species_id \\ @bovine_id) do
    %{species_id: species_id}
  end

  #--- Procedures --------------------------------------------------------------

  def procedure_frequency(repo, calculation_name) do
    schema = :procedure_frequency

    addition = Factory.sql_insert!(schema,
      name: calculation_name <> " procedure frequency",
      calculation_name: calculation_name)

    B.Schema.put(repo, schema, calculation_name, addition)
  end

  def procedure(repo, procedure_name, opts \\ []) do
    opts = Enum.into(opts, %{frequency: "unlimited"})

    repo = procedure_frequency(repo, opts.frequency)

    B.Schema.create_if_needed(repo, :procedure, procedure_name, fn ->
      frequency = B.Schema.get(repo, :procedure_frequency, opts.frequency)
      species_id = repo.species_id

      procedure =
        Factory.sql_insert!(:procedure,
          name: procedure_name,
          species_id: species_id,
          frequency_id: frequency.id)

      reloader(:procedure, procedure)
    end)
    |> B.Repo.shorthand(schema: :procedure, name: procedure_name)

  end

  def procedures(repo, names) do
    Enum.reduce(names, repo, fn name, acc ->
      apply &procedure/3, [acc, name, []]
    end)
  end

  # ---- Animals ---------------------------------------------------------------

  def animal(repo, animal_name, opts \\ []) do
    schema = :animal
    builder_map = animal_defaulted(opts)
    
    B.Schema.create_if_needed(repo, schema, animal_name, fn ->
      factory_opts = animal_factory_opts(repo, animal_name, builder_map)
      animal = Factory.sql_insert!(schema, factory_opts)
      reloader(schema, animal)
    end)
    |> B.Repo.shorthand(schema: schema, name: animal_name)
  end

  defp animal_defaulted(builder_opts) do 
    default = %{available: @earliest_date}
    B.Schema.combine_opts(builder_opts, default)
  end

  defp animal_factory_opts(repo, name, builder_map) do
    [name: name,
     span: compute_span(builder_map.available),
     species_id: repo.species_id]
  end

  defp reload_animal(repo, animal_name),
    do: B.Repo.load_fully(repo, &reloader/2, schema: :animal, name: animal_name)

  def animals(repo, names) do
    Enum.reduce(names, repo, fn name, acc ->
      apply &animal/3, [acc, name, []]
    end)
  end

  def service_gap_for(repo, animal_name, opts \\ []) do
    schema = :service_gap
    builder_map = service_gap_defaulted(opts)
    factory_opts = service_gap_factory_opts(repo, animal_name, builder_map)
    repo 
    |> B.Schema.create_if_needed(schema, builder_map.name, fn ->
         Factory.sql_insert!(schema, factory_opts)
       end)
    |> B.Repo.shorthand(schema: schema, name: builder_map.name)
    |> reload_animal(animal_name)
  end

  defp service_gap_defaulted(builder_opts) do
    defaults = %{
      starting: @earliest_date, ending: @latest_date,
      reason: Factory.unique(:repo_state),
      name: Factory.unique(:service_gap)}
    B.Schema.combine_opts(builder_opts, defaults)
  end

  defp service_gap_factory_opts(repo, animal_name, builder_map) do
    span = Datespan.customary(builder_map.starting, builder_map.ending)
    animal_id = id(repo, :animal, animal_name)
    [animal_id: animal_id, span: span, reason: builder_map.reason]
  end


  defp compute_span(%Date{} = earliest_date),
    do: Datespan.customary(earliest_date, @latest_date)
  defp compute_span(%Datespan{} = span),
    do: span

  # --- Reservations -----------------------------------------------------------

  def reservation_for(repo, animal_names, procedure_names, opts \\ []) do
    schema = :reservation
    species_id = repo.species_id
    name = Factory.unique("reservation")

    repo =
      repo
      |> procedures(procedure_names)
      |> animals(animal_names)

    addition =
      ReservationFocused.reserved!(species_id, animal_names, procedure_names, opts)

    B.Schema.put(repo, schema, name, addition)
  end

  # ----------------------------------------------------------------------------

  defp reloader(:procedure, value),
    do: reloader(Procedure.Get, Procedure, value)
  defp reloader(:animal, value),
    do: reloader(Animal.Get, Animal, value)
  defp reloader(_, value), do: value

  defp reloader(api, module, %{id: id}) do
    api.one_by_id(id, @institution, preload: module.associations())
  end

  #-----------------------------------------------------

  def id(repo, schema, name), do: B.Schema.get(repo, schema, name).id

  def ids(repo, schema, names) do
    for name <- names, do: id(repo, schema, name)
  end
end
