defmodule Crit.Sql.CommonSqlTest do
  use Crit.DataCase
  alias Crit.Sql.CommonSql
  alias Crit.Setup.Schemas.Procedure
  alias Crit.Setup.ProcedureApi

  setup do
    f = &insert/3
    f.("Equine only", @equine_id, @unlimited_frequency_id)
    f.("Bovine only", @bovine_id, @unlimited_frequency_id)
    f.("Both", @equine_id, @once_per_week_frequency_id)
    f.("Both", @bovine_id, @once_per_week_frequency_id)
    :ok
  end

  describe "cmd" do 
    test "simplest use is without preloads" do
      [bovine, both] =
        CommonSql.cmd(@institution, :all, Procedure, [species_id: @bovine_id])

      assert_fields(bovine,
        name: "Bovine only",
        species_id: @bovine_id,
        frequency_id: @unlimited_frequency_id)
      
      assert_fields(both,
        name: "Both",
        species_id: @bovine_id,
        frequency_id: @once_per_week_frequency_id)
    end
  end

  # describe "one" do
  #   test "simple use" do 
  #     id = insert("procedure", @bovine_id) |> ok_id
  #     actual = ProcedureApi.one_by_id(id, @institution)
  #     assert_fields(actual, 
  #                   id: id,
  #                   name: "procedure",
  #                   species_id: @bovine_id,
  #                   frequency_id: @unlimited_frequency_id)
  #   end

  #   test "loading assoc fields" do 
  #     id = insert("procedure", @bovine_id) |> ok_id
  #     actual = ProcedureApi.one_by_id(id,
  #       @institution)
  #     refute assoc_loaded?(actual.species)
  #     refute assoc_loaded?(actual.frequency)

  #     actual = ProcedureApi.one_by_id(id,
  #       [preload: [:species]], @institution)
  #     assert assoc_loaded?(actual.species)
  #     refute assoc_loaded?(actual.frequency)

  #     actual = ProcedureApi.one_by_id(id,
  #       [preload: [:species, :frequency]], @institution)
  #     assert assoc_loaded?(actual.species)
  #     assert assoc_loaded?(actual.frequency)
  #   end
    
  # end

  def insert(name, species_id, frequency_id) do
    attrs = %{name: name, species_id: species_id, frequency_id: frequency_id}
    ProcedureApi.insert(attrs, @institution)
  end
end
