defmodule Crit.Global do
  alias Crit.Repo
  alias Crit.Setup.Schemas.Institution

  def all_institutions() do
    Repo.all(Institution)
  end

  def timezone(institution) do
    institution = Repo.get_by!(Institution, short_name: institution)
    institution.timezone
  end
end
