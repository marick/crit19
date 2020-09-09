defmodule Crit.RepoState do
  use ExUnit.CaseTemplate
  use Crit.TestConstants
  alias Crit.Exemplars.ReservationFocused
  alias Crit.Factory
  alias Ecto.Datespan
  alias Crit.Schemas.{Animal, Procedure, Reservation}
  alias EctoTestDataBuilder, as: B
  require B.Macro


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

  B.Macro.make_plural_builder(:procedures, from: :procedure)
  

  # ---- Animals ---------------------------------------------------------------

  @doc """
  Shorthand: yes, fully_loaded: yes

  Options:

  * `available`: A `Date` or `Datespan`. A `Date` is converted to a
    "customary" `Datespan` with endpoint `@latest_date`.

  """
  def animal(repo, animal_name, opts \\ []) do
    schema = :animal
    builder_map = B.Schema.combine_opts(opts, animal_defaults())

    B.Schema.create_if_needed(repo, schema, animal_name, fn ->
      factory_opts = animal_factory_opts(repo, animal_name, builder_map)
      animal = Factory.sql_insert!(schema, factory_opts)
      reloader(schema, animal)
    end)
    |> B.Repo.shorthand(schema: schema, name: animal_name)
  end

  defp animal_defaults(), do: %{available: @earliest_date}

  defp animal_factory_opts(repo, name, builder_map) do
    [name: name,
     span: compute_span(builder_map.available),
     species_id: repo.species_id]
  end

  defp reload_animal(repo, animal_name),
    do: B.Repo.fully_load(repo, &reloader/2, schema: :animal, name: animal_name)

  B.Macro.make_plural_builder(:animals, from: :animal)

  # --- Service Gaps ----------------------------------------------------------
  
  @doc """
  Shorthand: yes, fully_loaded: yes

  Options:

  * `name:` You can name the service gap if it'll be mentioned in
    the test.
  * `starting:` A `Date`. Defaults to `@earliest_date`. 
  * `ending:` A `Date`. Defaults to `@latest_date`.
  * `reason:` A string giving the `reason` for the service gap.

  """
  def service_gap_for(repo, animal_name, opts \\ []) do
    schema = :service_gap
    builder_map = B.Schema.combine_opts(opts, service_gap_defaults())

    repo
    |> B.Schema.create_if_needed(schema, builder_map.name, fn ->
         factory_opts = service_gap_factory_opts(repo, animal_name, builder_map)
         Factory.sql_insert!(schema, factory_opts)
       end)
    |> B.Repo.shorthand(schema: schema, name: builder_map.name)
    |> reload_animal(animal_name)
  end

  defp service_gap_defaults do
    %{starting: @earliest_date, ending: @latest_date,
      reason: Factory.unique(:reason),
      name: Factory.unique(:service_gap)
    }
  end

  defp service_gap_factory_opts(repo, animal_name, builder_map) do
    span = Datespan.customary(builder_map.starting, builder_map.ending)
    animal_id = B.Schema.get(repo, :animal, animal_name).id
    [animal_id: animal_id, span: span, reason: builder_map.reason]
  end

  # --- Reservations -----------------------------------------------------------

  def reservation_for(repo, animal_names, procedure_names, opts \\ []) do
    schema = :reservation
    builder_map = B.Schema.combine_opts(opts, reservation_defaults())

    repo
    |> procedures(procedure_names)
    |> animals(animal_names)
    |> B.Schema.create_if_needed(schema, builder_map.name, fn -> 
         factory_opts = reservation_factory_opts(builder_map)
         reservation = 
           ReservationFocused.reserved!(
             repo.species_id, animal_names, procedure_names, factory_opts)
         reloader(schema, reservation)
       end)
    |> B.Repo.shorthand(schema: schema, name: builder_map.name)
  end

  defp reservation_defaults do
    %{name: Factory.unique(:reservation),
      date: @date_2,
    }
  end

  defp reservation_factory_opts(builder_map), 
    do: Enum.into(builder_map, [])

  # ----------------------------------------------------------------------------

  defp reloader(:procedure, value),
    do: reloader(Procedure.Get, Procedure, value)
  defp reloader(:animal, value),
    do: reloader(Animal.Get, Animal, value)
  defp reloader(:reservation, value),
    do: reloader(Reservation.Get, Reservation, value)
  defp reloader(_, value), do: value

  defp reloader(api, module, %{id: id}) do
    api.one_by_id(id, @institution, preload: module.associations())
  end

  #-----------------------------------------------------

  defp compute_span(%Date{} = earliest_date),
    do: Datespan.customary(earliest_date, @latest_date)
  defp compute_span(%Datespan{} = span),
    do: span

  defp id(repo, schema, name), do: B.Schema.get(repo, schema, name).id

  def ids(repo, schema, names) do
    for name <- names, do: id(repo, schema, name)
  end
end
