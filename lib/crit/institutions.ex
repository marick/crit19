defmodule Crit.Institutions do
  alias Crit.Repo
  alias Crit.Institutions.Institution

  def all() do
    Repo.all(Institution)
  end

  def timezone(institution) do
    institution = Repo.get_by!(Institution, short_name: institution)
    institution.timezone
  end
end
