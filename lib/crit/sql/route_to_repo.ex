defmodule Crit.Sql.RouteToRepo do
  # alias Crit.Repo
  @behaviour Crit.Sql.Router

  @moduledoc """
  Route to a particular Postgres schema by attaching an Ecto prefix.
  """

  @impl true
  def adjust(_all_but_last_arg, _given_opts, _institution) do
    :unimplemented
  end

  @impl true
  def forward(_sql_command, _all_but_last_arg, _given_opts, _institution) do
    :unimplemented
  end

  @impl true
  def multi_opts(_given_opts, _institution) do
    :unimplemented
  end
end
