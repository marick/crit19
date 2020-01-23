defmodule Crit.Setup.InstitutionApiTest do
  use Crit.DataCase
  alias Crit.Setup.Schemas.Institution
  alias Crit.Setup.InstitutionApi

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
    actual = InstitutionApi.timezone(@institution) 
    assert actual == InstitutionApi.default.timezone
  end

  test "an institution has tuples of species" do
    actual = InstitutionApi.available_species(@institution)
    expected = [{@bovine, @bovine_id}, {@equine, @equine_id}]
    assert actual == expected
  end
end
