defmodule CritBiz.ViewModels.Setup.ProcedureVM.LowerTowardRepoTest do
  use Crit.DataCase, async: true
  alias Crit.Exemplars.Params.BulkProcedures2, as: Params

  describe "`lower_changesets` to schema structs" do
    test "only one interesting case" do
      Params.check_form_lowering(:two_species)
      # But it doesn't hurt to check the rest.
      Params.check_form_lowering(:one_species)
    end
  end
end
