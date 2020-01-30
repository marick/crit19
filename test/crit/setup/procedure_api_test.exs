defmodule Crit.Setup.ProcedureApiTest do
  use Crit.DataCase
  alias Crit.Setup.Schemas.{Procedure}
  alias Crit.Setup.ProcedureApi

  setup do
    insert(name: "Equine only", species_id: @equine_id)
    insert(name: "Bovine only", species_id: @bovine_id)
    insert(name: "Both", species_id: @equine_id)
    insert(name: "Both", species_id: @bovine_id)
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
