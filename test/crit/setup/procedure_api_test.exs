defmodule Crit.Setup.ProcedureApiTest do
  use Crit.DataCase
  alias Crit.Setup.Schemas.{Procedure}
  alias Crit.Setup.ProcedureApi

  setup do
    f = fn name, species_id ->
      insert(name: name, species_id: species_id, frequency_id: @unlimited_frequency_id)
    end
    
    f.("Equine only", @equine_id)
    f.("Bovine only", @bovine_id)
    f.("Both", @equine_id)
    f.("Both", @bovine_id)
    :ok
  end

  describe "fetching procedures by species" do 
    test "bovine" do
      actual = ProcedureApi.all_by_species(@bovine_id, @institution)
      assert [%Procedure{name: "Bovine only", species_id: @bovine_id},
              %Procedure{name: "Both", species_id: @bovine_id}] = actual
    end      
  end

  def insert(opts) do 
    attrs = Enum.into(opts, %{})
    ProcedureApi.insert(attrs, @institution)
  end

  
end
