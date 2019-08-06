defmodule Crit.Institutions do
  alias Crit.Repo
  alias Crit.Institutions.Institution
  def all() do
    Repo.all(Institution, prefix: "clients")
  end
end
