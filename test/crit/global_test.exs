defmodule Crit.GlobalTest do
  use Crit.DataCase
  alias Crit.Global
  alias Crit.Global.Institution
  use Crit.Global.Default

  test "the default user changeset contains permissions" do
    assert [preloaded] = Repo.all(Institution)
    assert [retrieved] = Global.all_institutions()
    assert preloaded == retrieved
    assert retrieved.short_name == @institution
    assert retrieved.prefix == Global.Default.institution.prefix
    assert retrieved.display_name == Global.Default.institution.display_name
  end


  test "timezone retrieval" do
    actual = Global.timezone(@institution) 
    assert actual == Global.Default.institution.timezone
  end
end
