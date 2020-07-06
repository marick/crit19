defmodule CritBiz.ViewModels.Setup.BulkAnimalVM.LowerTowardRepoTest do
  use Crit.DataCase, async: true
  alias CritBiz.ViewModels.Setup, as: VM
  alias Crit.Setup.Schemas
  alias Ecto.Datespan

  @params %{"names" => "animal 1, b, c ",
            "species_id" => to_string(@bovine_id),
            "in_service_datestring" => @iso_date_1,
            "out_of_service_datestring" => @iso_date_2}
  

  test "converting to a list of insertable animals" do
    {:ok, changeset} = VM.BulkAnimalNew.accept_form(@params, @institution)
    
    [a, b, c] = VM.BulkAnimalNew.lower_changeset(changeset)

    assert_as_expected(a, "animal 1")
    assert_as_expected(b, "b")
    assert_as_expected(c, "c")
  end


  # ----------------------------------------------------------------------------
  defp assert_as_expected(animal, name) do
    animal
    |> assert_shape(%Schemas.Animal{})
    |> assert_field(id: nil,
                    name: name,
                    span: Datespan.customary(@date_1, @date_2),
                    species_id: @bovine_id,
                    available: true,
                    lock_version: 1)
    |> refute_assoc_loaded(:service_gaps)
  end
end
