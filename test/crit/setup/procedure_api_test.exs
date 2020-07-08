defmodule Crit.Setup.ProcedureApiTest do
  use Crit.DataCase
  alias Crit.Schemas.{Procedure}
  alias Crit.Setup.ProcedureApi

  setup do
    f = &insert/2
    f.("Equine only", @equine_id)
    f.("Bovine only", @bovine_id)
    f.("Both", @equine_id)
    f.("Both", @bovine_id)
    :ok
  end

  ### The following are cursory tests of generated functions. 

  describe "fetching procedures by species" do
    test "bovine" do
      actual = ProcedureApi.all_by_species(@bovine_id, @institution)
      assert [%Procedure{name: "Both", species_id: @bovine_id},
              %Procedure{name: "Bovine only", species_id: @bovine_id}] = actual
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
      actual = ProcedureApi.one_by_id(id, @institution, preload: [:species])
      assert assoc_loaded?(actual.species)
      refute assoc_loaded?(actual.frequency)
    end
  end

  describe "all_by_ids" do
    test "simple use" do
      id1 = insert("returned", @bovine_id) |> ok_id
      _id2 = insert("skipped", @bovine_id) |> ok_id
      assert [actual] = ProcedureApi.all_by_ids([id1], @institution)
      assert_fields(actual, 
                    id: id1,
                    name: "returned",
                    species_id: @bovine_id,
                    frequency_id: @unlimited_frequency_id)
    end

    test "loading assoc fields" do 
      id = insert("procedure", @bovine_id) |> ok_id
      [actual] = ProcedureApi.all_by_ids([id], @institution, preload: [:species])
      assert assoc_loaded?(actual.species)
      refute assoc_loaded?(actual.frequency)
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
