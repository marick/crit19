defmodule Crit.GlobalTest do
  use Crit.DataCase
  alias Crit.Global
  alias Crit.Global.Institution
  use Crit.Global.Default

  test "the institutions are preloaded when app starts" do
    assert Global.all_institutions() == Repo.all(Institution)
  end

  test "during testing, there's a single institution" do
    assert [_] = Global.all_institutions()
  end
  
  test "the institution is labeled with a special shortname" do
    [retrieved] = Global.all_institutions()

    assert retrieved.short_name == @institution
  end

  test "an institution has a timezone" do
    actual = Global.timezone(@institution) 
    assert actual == Global.Default.institution.timezone
  end
end
