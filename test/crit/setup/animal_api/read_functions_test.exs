defmodule Crit.Setup.Schemas.AnimalApi.ReadFunctionsTest do
  use Crit.DataCase, async: true
  alias Crit.Setup.AnimalApi
  alias Crit.Setup.AnimalImpl.Read

  describe "updatable!" do
    @tag :skip
    test "failure" do
      assert_raise KeyError, fn ->
        AnimalApi.updatable!(1, @institution)
      end
    end
  end

  test "`ids_to_animals`" do
    given Read.ids_to_animals, [@id_list__, @institution], do: @animal_list__
    given Read.put_updatable_fields, [@animal_list__, @institution], do: :updatable__list
    
    assert AnimalApi.ids_to_animals(@id_list__, @institution) == :updatable__list
  end

  test "`all`" do
    given Read.all, [@institution], do: @animal_list__
    given Read.put_updatable_fields, [@animal_list__, @institution], do: :updatable__list
    
    assert AnimalApi.all(@institution) == :updatable__list
  end
end
