defmodule Crit.Servers.Institution.Supervisor do
  use Supervisor
  alias Crit.Schemas
  alias Crit.Servers.Institution

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    Schemas.Institution.all
    |> Enum.map(fn institution ->
         Supervisor.child_spec({Institution.Server, institution},
           id: institution.short_name)
    end)
    |> Supervisor.init(strategy: :one_for_one)
  end
end
