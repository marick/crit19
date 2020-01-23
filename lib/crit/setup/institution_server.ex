defmodule Crit.Setup.InstitutionServer do
  use GenServer
  alias Crit.Setup.Schemas.Institution
  alias Crit.Sql.RouteToSchema

  defstruct institution: nil, router: nil
  

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
  def handle_call(:reload, _from, state) do
    short_name = state.institution.short_name
    new_institution = Crit.Repo.get_by!(Institution, short_name: short_name)
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
  

  # Util
  defp new_state(institution) do
    router = if institution.prefix, do: RouteToSchema, else: RouteToRepo
    %__MODULE__{institution: institution, router: router}
  end

  
end
