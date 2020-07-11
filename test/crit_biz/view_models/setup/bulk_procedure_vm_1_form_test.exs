defmodule CritBiz.ViewModels.Setup.BulkProcedureFormTest do
  use Crit.DataCase
  alias CritBiz.ViewModels.Setup, as: VM
  alias Ecto.Changeset

  test "the starting changesets" do
    [first | rest] = VM.BulkProcedure.fresh_form_changesets()

    assert length([first|rest]) == 10

    first
    |> assert_shape(%Changeset{})
    |> assert_data(index: 0,
                   name: "",
                   species_ids: [],
                   frequency_id: nil)
  end
end
  
