defmodule Crit.InstitutionsTest do
  use Crit.DataCase
  alias Crit.Institutions
  alias Crit.Institutions.Institution
  alias Crit.Repo

  test "the fresh/default user changeset contains permissions" do

    assert [preloaded] = Repo.all(Institution, prefix: "clients")
    assert [retrieved] = Institutions.all()
    assert preloaded == retrieved
    assert retrieved.short_name == "critter4us"
    assert retrieved.prefix == "demo"
    assert retrieved.display_name == "Critter4Us Demo"
  end
end
