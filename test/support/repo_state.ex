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
    B.Schema.create_if_needed(repo, :animal, animal_name, fn ->
      opts =
        Enum.into(opts, %{
              available: @earliest_date,
              species_id: repo.species_id})

      animal = Factory.sql_insert!(:animal,
        name: animal_name,
        span: compute_span(opts.available),
        species_id: opts.species_id)

      reloader(:animal, animal)
    end)
    |> B.Repo.shorthand(schema: :animal, name: animal_name)
  end

  def reload_animal(repo, animal_name),
    do: B.Repo.reload(repo, &reloader/2, schema: :animal, name: animal_name)

  def animals(repo, names) do
    Enum.reduce(names, repo, fn name, acc ->
      apply &animal/3, [acc, name, []]
    end)
  end

  def service_gap_for(repo, animal_name, opts \\ []) do
    opts = Enum.into(opts, %{
          starting: @earliest_date, ending: @latest_date,
          reason: Factory.unique(:repo_state),
          name: Factory.unique(:service_gap)})
    animal_id = id(repo, :animal, animal_name)
    span = Datespan.customary(opts.starting, opts.ending)

    repo 
    |> B.Schema.create_if_needed(:service_gap, opts.name, fn ->
         details = [animal_id: animal_id, span: span, reason: opts.reason]
         Factory.sql_insert!(:service_gap, details, @institution)
       end)
    |> B.Repo.shorthand(schema: :service_gap, name: opts.name)
    |> reload_animal(animal_name)
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
