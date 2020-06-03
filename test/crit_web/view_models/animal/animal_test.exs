defmodule CritWeb.ViewModels.Animal.AnimalTest do
  use Crit.DataCase, async: true
  alias CritWeb.ViewModels.Animal.Animal, as: ViewModel
  # alias Crit.Setup.Schemas
  alias Crit.Setup.AnimalApi
  import Crit.Exemplars.Background
  alias Ecto.Datespan

  setup do
    b = 
      background(@bovine_id)
      |> animal("Bossie", span: Datespan.customary(@date_1, @date_2))
      |> shorthand
    [background: b]
  end

  def with_only_species(id),
    do: AnimalApi.one_by_id(id, @institution, preload: [:species])
    

  test "a shallow fetch (does not include service gaps)", %{background: b} do
    with_only_species(b.bossie.id)
    |> ViewModel.from_ecto(@institution)
    |> assert_fields(available: true,
                     lock_version: 1,
                     name: "Bossie",
                     species_name: @bovine)
    |> refute_assoc_loaded(:service_gaps)
  end

end
