defmodule Crit.Sql.Supervisor do
  use Supervisor
  alias Crit.Sql.Servers

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {Servers, name: Servers}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
