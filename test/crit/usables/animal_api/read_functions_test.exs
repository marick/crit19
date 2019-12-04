defmodule Crit.Usables.Schemas.AnimalApi.ReadFunctionsTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.AnimalImpl.Read 

  describe "updatable!" do
    test "success" do
      given Read.one, [[id: @id__], @institution], do: @animal__
      given Read.put_updatable_fields, [@animal__], do: :updatable__
      
      assert AnimalApi.updatable!(@id__, @institution) == :updatable__
    end

    test "failure" do
      given Read.one, [[id: @id__], @institution], do: nil

      assert_raise KeyError, fn ->
        AnimalApi.updatable!(@id__, @institution)
      end
    end
  end

  describe "updatable_by" do
    test "success" do
      given Read.one, [[field__: :value__], @institution], do: @animal__
      given Read.put_updatable_fields, [@animal__], do: :updatable__
      
      assert AnimalApi.updatable_by(:field__, :value__, @institution) == :updatable__
    end

    test "failure" do
      given Read.one, [[field__: :value__], @institution], do: nil

      assert AnimalApi.updatable_by(:field__, :value__, @institution) == nil
    end
  end

  test "`ids_to_animals`" do
    given Read.ids_to_animals, [@id_list__, @institution], do: @animal_list__
    given Read.put_updatable_fields, [@animal_list__], do: :updatable__list
    
    assert AnimalApi.ids_to_animals(@id_list__, @institution) == :updatable__list
  end

  test "`all`" do
    given Read.all, [@institution], do: @animal_list__
    given Read.put_updatable_fields, [@animal_list__], do: :updatable__list
    
    assert AnimalApi.all(@institution) == :updatable__list
  end
end
