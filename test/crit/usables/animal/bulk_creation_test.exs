defmodule Crit.Usables.Animal.BulkCreationTest do
  use Crit.DataCase
  alias Crit.Usables
  alias Crit.Usables.AnimalApi
  import Ecto.ChangesetX

  @basic_params %{
    "species_id" => @bovine_id,
    "names" => "Bossie, Jake",
    "start_date" => @iso_date,
    "end_date" => @never
  }

  test "an error produces a changeset" do
    params =
      @basic_params
      |> Map.put("start_date", @later_iso_date)
      |> Map.put("end_date", @iso_date)
      |> Map.put("names", ",")
    
    assert {:error, changeset} = Usables.create_animals(params, @institution)
    assert represents_form_errors?(changeset)

    errors = errors_on(changeset)
    assert [_message] = errors.end_date
    assert [_message] = errors.names
  end

  test "without an error, we insert a network" do
    {:ok, [bossie, jake]} = Usables.create_animals(@basic_params, @institution)

    check = fn returned ->
      fetched = AnimalApi.showable!(returned.id, @institution)
      assert fetched.id == returned.id
      assert fetched.name == returned.name
      assert fetched.in_service_date == @iso_date
      assert fetched.out_of_service_date == @never
      assert returned.species_name == @bovine
    end

    check.(bossie)
    check.(jake)
  end

  test "constraint problems are detected last" do
    {:ok, [_bossie, _jake]} = Usables.create_animals(@basic_params, @institution)
    {:error, changeset} =   Usables.create_animals(@basic_params, @institution)

    assert ~s|An animal named "Bossie" is already in service| in errors_on(changeset).names
  end
end    
