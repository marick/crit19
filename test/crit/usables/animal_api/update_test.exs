defmodule Crit.Usables.AnimalApi.UpdateTest do
  use Crit.DataCase, async: true
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.AnimalImpl.Write

  test "only possibility" do
    given AnimalApi.updatable!, [@id__, @institution], do: @animal__
    given Write.update, [@animal__, @params__, @institution], do: :result__
    
    assert AnimalApi.update(@id__, @params__, @institution) == :result__
  end
end
