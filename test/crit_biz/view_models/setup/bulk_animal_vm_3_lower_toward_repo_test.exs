defmodule CritBiz.ViewModels.Setup.BulkAnimalVM.LowerTowardRepoTest do
  use Crit.DataCase, async: true
  alias Crit.Exemplars.Params.BulkAnimal, as: Params

  test "validate specific cases" do
    Params.validate(:lowered, :valid)
  end
end
