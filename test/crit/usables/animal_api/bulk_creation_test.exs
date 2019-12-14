defmodule Crit.Usables.AnimalApi.BulkCreationTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalApi

  @basic_params %{
    "species_id" => @bovine_id,
    "names" => "Bossie, Jake",
    "in_service_datestring" => @iso_date,
    "out_of_service_datestring" => @never
  }

  test "creates multiple animals at once" do
    {:ok, [bossie, jake]} = AnimalApi.create_animals(@basic_params, @institution)

    check_animal_properties_inserted = fn returned ->
      AnimalApi.updatable!(returned.id, @institution)
      |> assert_fields(id: returned.id,
                       name: returned.name,
                       in_service_datestring: @iso_date,
                       out_of_service_datestring: @never,
                       species_name: @bovine)
    end

    check_animal_properties_inserted.(bossie)
    check_animal_properties_inserted.(jake)
  end

  test "a error returns a changeset" do
    params =
      @basic_params
      |> Map.put("in_service_datestring", @later_iso_date) # out of order
      |> Map.put("out_of_service_datestring", @iso_date)
      |> Map.put("names", ",") # no name

    assert {:error, changeset} = AnimalApi.create_animals(params, @institution)

    changeset
    |> assert_errors([:names, :out_of_service_datestring])
    |> assert_error_free(:in_service_datestring)
  end

  test "constraint problems are detected last" do
    {:ok, _} = AnimalApi.create_animals(@basic_params, @institution)
    {:error, changeset} = AnimalApi.create_animals(@basic_params, @institution)

    assert ~s|An animal named "Bossie" is already in service| in errors_on(changeset).names
  end
end
