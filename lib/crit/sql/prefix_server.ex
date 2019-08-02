defmodule Crit.Sql.PrefixServer do
  use GenServer
  alias Crit.Repo

  def start_link(prefix),
    do: GenServer.start_link(__MODULE__, prefix)

  # Server part

  @impl GenServer
  def init(prefix) do
    {:ok, prefix}
  end

  @impl GenServer
  def handle_call({sql_command, all_but_last_arg, given_opts}, _from, prefix) do
    adjusted_opts = given_opts ++ [{:prefix, prefix}]
    retval = apply(Repo, sql_command, all_but_last_arg ++ [adjusted_opts])
    {:reply, retval, prefix}
  end
end
