defmodule Crit.Setup.InstitutionApiTest do
  use Crit.DataCase
  alias Crit.Global
  alias Crit.Setup.Schemas.Institution
  alias Crit.Setup.InstitutionApi
  use Crit.Global.Default

  test "the institutions are preloaded when app starts" do
    assert InstitutionApi.all == Repo.all(Institution)
  end

  test "during testing, there's a single institution" do
    assert [_] = InstitutionApi.all
  end
  
  test "the institution is labeled with a special shortname" do
    [retrieved] = InstitutionApi.all

    assert retrieved.short_name == @institution
  end

  test "an institution has a timezone" do
    actual = Global.timezone(@institution) 
    assert actual == InstitutionApi.default.timezone
  end
end
