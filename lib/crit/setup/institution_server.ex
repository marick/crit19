defmodule Crit.Setup.InstitutionServer do
  use GenServer
  alias Crit.Sql.RouteToSchema
  alias Crit.Setup.HiddenSchemas.{Species,ProcedureFrequency}
  alias Crit.Sql.CommonQuery
  alias Crit.Setup.InstitutionApi

  defstruct institution: nil, router: nil, species: [], procedure_frequencies: []
  

  def server(short_name), do: String.to_atom(short_name)

  def start_link(institution),
    do: GenServer.start_link(__MODULE__, institution,
          name: server(institution.short_name))

  # Server part

  @impl true
  def init(institution) do
    {:ok, new_state(institution)}
  end

  @impl true
  def handle_call(:raw, _from, state) do
    {:reply, state.institution, state}
  end

  @impl true
  def handle_call(:timeslots, _from, state) do
    {:reply, state.institution.timeslots, state}
  end

  @impl true
  def handle_call(:timeslot_tuples, _from, state) do
    tuples = 
      state.institution.timeslots
      |> EnumX.id_pairs(:name)
    {:reply, tuples, state}
  end

  @impl true
  def handle_call({:timeslot_by_id, slot_id}, _from, state) do
    result = 
      state.institution.timeslots
      |> EnumX.find_by_id(slot_id)
    {:reply, {:ok, result}, state}
  end

  @impl true
  def handle_call(:available_species, _from, state) do
    {:reply, state.species, state}
  end

  @impl true
  def handle_call(:procedure_frequencies, _from, state) do
    {:reply, state.procedure_frequencies, state}
  end

  @impl true
  def handle_call(:reload, _from, state) do
    short_name = state.institution.short_name
    new_institution = InstitutionApi.one!(short_name: short_name)
    {:reply, :ok, new_state(new_institution)}
  end

  @impl true
  def handle_call({:multi_opts, given_opts}, _from, state) do
    retval = state.router.multi_opts(given_opts, state.institution)
    {:reply, retval, state}
  end

  @impl true
  def handle_call({:sql, sql_command, all_but_last_arg, given_opts}, _from, state) do
    retval =
      state.router.forward(sql_command, all_but_last_arg, given_opts,
        state.institution)
    {:reply, retval, state}
  end

  @impl true
  def handle_call({:adjust, all_but_last_arg, given_opts}, _from, state) do
    retval =
      state.router.adjust(all_but_last_arg, given_opts, state.institution)
    {:reply, retval, state}
  end
  
  # ----------------------------------------------------------------------------
  # Util
  defp new_state(institution) do
    router = if institution.prefix, do: RouteToSchema, else: RouteToRepo
    all = fn module ->
      router.forward(:all, [CommonQuery.ordered_by_name(module)], [], institution)
    end
    
    %__MODULE__{institution: institution,
                router: router,
                species: all.(Species) |> EnumX.id_pairs(:name),
                procedure_frequencies: all.(ProcedureFrequency)
                }
  end
end
