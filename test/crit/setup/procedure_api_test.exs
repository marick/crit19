defmodule Crit.Setup.ProcedureApiTest do
  use Crit.DataCase
  alias Crit.Setup.Schemas.{Procedure}
  alias Crit.Setup.ProcedureApi

  setup do
    f = &insert/2
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

  describe "one" do
    test "simple use" do 
      id = insert("procedure", @bovine_id) |> ok_id
      actual = ProcedureApi.one_by_id(id, @institution)
      assert_fields(actual, 
                    id: id,
                    name: "procedure",
                    species_id: @bovine_id,
                    frequency_id: @unlimited_frequency_id)
    end

    test "loading assoc fields" do 
      id = insert("procedure", @bovine_id) |> ok_id
      actual = ProcedureApi.one_by_id(id,
        @institution)
      refute assoc_loaded?(actual.species)
      refute assoc_loaded?(actual.frequency)

      actual = ProcedureApi.one_by_id(id,
        [preload: [:species]], @institution)
      assert assoc_loaded?(actual.species)
      refute assoc_loaded?(actual.frequency)

      actual = ProcedureApi.one_by_id(id,
        [preload: [:species, :frequency]], @institution)
      assert assoc_loaded?(actual.species)
      assert assoc_loaded?(actual.frequency)
    end
    
  end

  def insert(name, species_id) when is_binary(name) and is_integer(species_id) do 
    insert(name: name, species_id: species_id,
      frequency_id: @unlimited_frequency_id)
  end
    
  def insert(opts) do 
    attrs = Enum.into(opts, %{})
    ProcedureApi.insert(attrs, @institution)
  end

  
end
