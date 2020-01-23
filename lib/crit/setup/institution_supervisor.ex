defmodule Crit.Setup.InstitutionSupervisor do
  use Supervisor
  alias Crit.Setup.InstitutionApi
  alias Crit.Setup.InstitutionServer

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    InstitutionApi.all
    |> Enum.map(fn institution ->
         Supervisor.child_spec({InstitutionServer, institution},
           id: institution.short_name)
       end)
    |> Supervisor.init(strategy: :one_for_one)
  end
end
