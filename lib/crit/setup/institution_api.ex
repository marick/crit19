defmodule Crit.Setup.InstitutionApi do
  alias Crit.Repo
  alias Crit.Setup.Schemas.Institution

  def all do
    Repo.all(Institution)
  end

  
end
