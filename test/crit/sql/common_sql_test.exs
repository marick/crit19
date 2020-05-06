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
      [both, bovine] =
        CommonSql.typical(@institution, :all, Procedure, [species_id: @bovine_id])

      # Note that they are ordered by name
      assert_fields(both,
        name: "Both",
        species_id: @bovine_id,
        frequency_id: @once_per_week_frequency_id)

      assert_fields(bovine,
        name: "Bovine only",
        species_id: @bovine_id,
        frequency_id: @unlimited_frequency_id)
    end

    test "can use commands other than `all`'" do
      id = insert("procedure", @bovine_id, @unlimited_frequency_id) |> ok_id
      actual = CommonSql.typical(@institution, :one, Procedure, [id: id])
      assert_fields(actual, 
        id: id,
        name: "procedure",
        species_id: @bovine_id,
        frequency_id: @unlimited_frequency_id)
    end

    test "preloads can be given" do
      id = insert("procedure", @bovine_id, @unlimited_frequency_id) |> ok_id

      run = fn opts ->
        CommonSql.typical(@institution, :one, Procedure, [id: id], preload: opts)
      end

      run.(                  [])
      |> assert_assoc_loaded([                    ])
      |> refute_assoc_loaded([:species, :frequency])

      run.(                  [:species])
      |> assert_assoc_loaded([:species            ])
      |> refute_assoc_loaded([          :frequency])

      run.(                  [:species, :frequency])
      |> assert_assoc_loaded([:species, :frequency])
      |> refute_assoc_loaded([                    ])
    end
  end

  def insert(name, species_id, frequency_id) do
    attrs = %{name: name, species_id: species_id, frequency_id: frequency_id}
    ProcedureApi.insert(attrs, @institution)
  end
end
