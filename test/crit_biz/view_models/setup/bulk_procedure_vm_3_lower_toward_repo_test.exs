defmodule CritBiz.ViewModels.Setup.ProcedureVM.LowerTowardRepoTest do
  use Crit.DataCase, async: true
  alias Crit.Exemplars.Params.BulkProcedures, as: Params
  alias Crit.Schemas

  describe "`lower_changesets` to schema structs" do
    test "only interesting case" do
      assert [bovine, equine] = Params.lower_changesets(:two_species)

      bovine
      |> assert_shape(%Schemas.Procedure{})
      |> assert_fields(Params.as_cast(:two_species, without: [:species_ids]))
      |> assert_field(species_id: @bovine_id)

      equine
      |> assert_copy(bovine, except: [species_id: @equine_id])
    end
  end
end
