defmodule CritBiz.ViewModels.Setup.BulkProcedureVM.InsertAllTest do
  use Crit.DataCase, async: true
  alias CritBiz.ViewModels.Setup, as: VM
  alias Crit.Schemas

  setup do
    procedure = Factory.build(:procedure,
      name: "Embryo transfer",
      frequency_id: @once_per_week_frequency_id,
      species_id: @bovine_id)
    [procedure: procedure]
  end

  describe "success" do
    test "what the on-disk version looks like", %{procedure: procedure} do
      {:ok, [%{id: id}]} = VM.BulkProcedure.insert_all([procedure], @institution)

      Schemas.Procedure.Get.one_by_id(id, @institution)
      |> assert_schema_copy(procedure, ignoring: [:id])
    end

    test "what the returned view models look like", %{procedure: procedure} do
      {:ok, [view_model]} = VM.BulkProcedure.insert_all([procedure], @institution)

      view_model
      |> assert_shape(%VM.Procedure{})
      |> assert_fields(frequency_name: "once per week",
                       name: procedure.name,
                       species_name: @bovine)
    end
  end

  test "trying to rename a procedure to an existing procedure",
    %{procedure: procedure} do

    assert {:ok, _} = VM.BulkProcedure.insert_all([procedure], @institution)

    assert {:error, :constraint, %{duplicate_name: duplicate_name}} = 
      VM.BulkProcedure.insert_all([procedure], @institution)

    assert duplicate_name == procedure.name
  end
end
