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

    # Existing procedure
    assert {:ok, _} = VM.BulkProcedure.insert_all([procedure], @institution)

    # Let's not have the first procedure be the one with the problem.
    ok_procedure = Factory.build(:procedure, name: "ok name")

    assert {:error, :constraint, description} = 
      VM.BulkProcedure.insert_all([ok_procedure, procedure], @institution)

    description
    |> assert_fields(duplicate_name: 1,
                     message: "A procedure named \"#{procedure.name}\" already exists for species bovine")
  end
end
