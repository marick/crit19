defmodule CritBiz.ViewModels.Setup.BulkAnimalFormTest do
  use Crit.DataCase
  alias CritBiz.ViewModels.Setup, as: VM

  test "the starting changeset" do
    VM.BulkAnimalNew.fresh_form_changeset()
    |> assert_data(names: "",
                   in_service_datestring: @today,
                   out_of_service_datestring: @never)
  end
end
  
