defmodule CritWeb.ViewModels.Animal.AnimalTest do
  use Crit.DataCase, async: true
  alias CritWeb.ViewModels.Animal.Animal, as: ViewModel
  alias Crit.Setup.Schemas
  alias Crit.Setup.AnimalApi
#  alias Crit.Exemplars.Background
  alias Ecto.Datespan

  test "a shallow fetch (does not include service gaps)" do
    %Schemas.Animal{} = original = Factory.sql_insert!(:animal_new,
      name: "Bossie",
      species_id: @bovine_id,
      span: Datespan.customary(@date_1, @date_2))

    _actual =
      AnimalApi.one_by_id(original.id, @institution, preload: [:species])
      |> ViewModel.from_ecto(@institution)
      |> assert_fields(available: true,
                       lock_version: 1,
                       name: "Bossie",
                       species_name: @bovine)
      
  end

end
