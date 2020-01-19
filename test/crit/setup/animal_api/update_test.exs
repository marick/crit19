defmodule Crit.Setup.AnimalApi.UpdateTest do
  use Crit.DataCase, async: true
  alias Crit.Setup.AnimalApi
  alias Crit.Setup.AnimalImpl.Write

  test "only possibility" do
    given AnimalApi.updatable!, [@id__, @institution], do: @animal__
    given Write.update, [@animal__, @params__, @institution], do: :result__
    
    assert AnimalApi.update(@id__, @params__, @institution) == :result__
  end
end
