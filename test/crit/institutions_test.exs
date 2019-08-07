defmodule Crit.InstitutionsTest do
  use Crit.DataCase
  alias Crit.Institutions
  alias Crit.Institutions.Institution
  alias Crit.Repo

  test "the fresh/default user changeset contains permissions" do

    assert [preloaded] = Repo.all(Institution, prefix: "clients")
    assert [retrieved] = Institutions.all()
    assert preloaded == retrieved
    assert retrieved.short_name == Institutions.default_institution.short_name
    assert retrieved.prefix == Institutions.default_institution.prefix
    assert retrieved.display_name == Institutions.default_institution.display_name
  end
end
