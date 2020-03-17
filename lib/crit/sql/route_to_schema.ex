defmodule Crit.Sql.RouteToSchema do
  alias Crit.Repo
  @behaviour Crit.Sql.Router

  @moduledoc """
  Route to a particular Postgres schema by attaching an Ecto prefix.
  """

  @impl true
  def adjust(all_but_last_arg, given_opts, institution) do
    adjusted_opts = given_opts ++ [prefix_opt(institution)]
    [Repo, all_but_last_arg ++ [adjusted_opts]]
  end

  
  @impl true
  def forward(sql_command, all_but_last_arg, given_opts, institution) do
    adjusted_opts = given_opts ++ [prefix_opt(institution)]
    apply(Repo, sql_command, all_but_last_arg ++ [adjusted_opts])
  end

  @impl true
  def multi_opts(given_opts, institution) do
    [prefix_opt(institution) | given_opts]
  end

  defp prefix_opt(institution), do: {:prefix, institution.prefix}
end
