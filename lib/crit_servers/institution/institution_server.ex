defmodule Crit.Servers.Institution.Server do
  use GenServer
  alias Crit.Sql.RouteToSchema
  alias Crit.Schemas.{Species,ProcedureFrequency, Institution, Timeslot}
  alias Crit.Sql.CommonQuery
  alias Crit.Repo
  
  defstruct institution: nil, router: nil,
    species: [],
    procedure_frequencies: [],
    timeslots: []
  

  def server(short_name), do: String.to_atom(short_name)

  def start_link(institution),
    do: GenServer.start_link(__MODULE__, institution,
          name: server(institution.short_name))

  # ----------------------------------------------------------------------------
  # Server part

  @impl true
  def init(institution) do
    {:ok, new_state(institution)}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    {:reply, Map.fetch!(state, key), state}
  end

  @impl true
  def handle_call(:reload, _from, state) do
    short_name = state.institution.short_name
    new_institution =
      Institution
      |> CommonQuery.start(short_name: short_name)
      |> Repo.one!
    {:reply, :ok, new_state(new_institution)}
  end

  @impl true
  def handle_call({:multi_opts, given_opts}, _from, state) do
    retval = state.router.multi_opts(given_opts, state.institution)
    {:reply, retval, state}
  end

  @impl true
  def handle_call(
    {:adjusted_repo_call, all_but_last_arg, given_opts}, _from, state) do
    retval =
      state.router.adjust(all_but_last_arg, given_opts, state.institution)
    {:reply, retval, state}
  end
  
  # ----------------------------------------------------------------------------
  # Util
  defp new_state(institution) do
    router = if institution.prefix, do: RouteToSchema, else: RouteToRepo
    all = fn query ->
      router.forward(:all, [query], [], institution)
    end
    by_name = &(all.(CommonQuery.ordered_by_name(&1)))
    
    %__MODULE__{institution: institution,
                router: router,
                species: by_name.(Species),
                procedure_frequencies: by_name.(ProcedureFrequency),
                timeslots: all.(Timeslot)
                }
  end
end
