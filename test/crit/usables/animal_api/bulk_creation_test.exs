defmodule Crit.Usables.AnimalApi.BulkCreationTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalApi
  import Ecto.ChangesetX

  @basic_params %{
    "species_id" => @bovine_id,
    "names" => "Bossie, Jake",
    "start_date" => @iso_date,
    "end_date" => @never
  }

  test "creates multiple animals at once" do
    {:ok, [bossie, jake]} = AnimalApi.create_animals(@basic_params, @institution)

    check_animal_properties_inserted = fn returned ->
      fetched = AnimalApi.showable!(returned.id, @institution)
      assert fetched.id == returned.id
      assert fetched.name == returned.name
      assert fetched.in_service_date == @iso_date
      assert fetched.out_of_service_date == @never
      assert returned.species_name == @bovine
    end

    check_animal_properties_inserted.(bossie)
    check_animal_properties_inserted.(jake)
  end

  test "an error returns a changeset" do
    params =
      @basic_params
      |> Map.put("start_date", @later_iso_date)
      |> Map.put("end_date", @iso_date)
      |> Map.put("names", ",")

    assert {:error, changeset} = AnimalApi.create_animals(params, @institution)
    assert represents_form_errors?(changeset)

    errors = errors_on(changeset)
    assert length(errors.end_date) == 1
    assert length(errors.names) == 1
  end

  test "constraint problems are detected last" do
    {:ok, _} = AnimalApi.create_animals(@basic_params, @institution)
    {:error, changeset} = AnimalApi.create_animals(@basic_params, @institution)

    assert ~s|An animal named "Bossie" is already in service| in errors_on(changeset).names
  end
end
