defmodule Crit.Setups do
  use Crit.TestConstants
  alias Crit.Setup.AnimalApi
  alias Crit.Factory


  # Let's set the context: an animal with one service gap. It will be edited in
  # various ways. 
  def an_updatable_animal_with_one_service_gap(_) do
    %{id: animal_id} = Factory.sql_insert!(:animal, @institution)
    Factory.sql_insert!(:service_gap, [animal_id: animal_id], @institution)
    
    [animal: AnimalApi.updatable!(animal_id, @institution)]
  end
end

