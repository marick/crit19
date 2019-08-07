defmodule Crit.Institutions do
  alias Crit.Repo
  alias Crit.Institutions.Institution

  def all() do
    Repo.all(Institution, prefix: "clients")
  end

  @doc """
  This institution must be in the database(s) for all environments: dev, prod, test. 
  It is also "default" in the sense that a dropdown list of institutions should
  show/select this one by default.
  """
  def default_institution do
    %Institution{
      display_name: "Critter4Us Demo",
      short_name: "critter4us",
      prefix: "demo"
    }
  end
  
end
