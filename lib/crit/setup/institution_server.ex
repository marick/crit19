defmodule Crit.Setup.InstitutionServer do
  use GenServer
  alias Crit.Setup.Schemas.Institution

  def start_link(institution),
    do: GenServer.start_link(__MODULE__, institution, name: String.to_atom(institution.short_name))

  # Server part

  @impl true
  def init(institution) do
    {:ok, institution}
  end

  @impl true
  def handle_call(:raw, _from, institution) do
    {:reply, institution, institution}
  end

  @impl true
  def handle_call(:reload, _from, institution) do
    next = Crit.Repo.get_by!(Institution, short_name: institution.short_name)
    {:reply, :ok, next}
  end
end
