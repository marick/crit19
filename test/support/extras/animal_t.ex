defmodule Crit.Extras.AnimalT do
  @moduledoc """
  Shorthand functions for use in tests.
  """

  use Crit.TestConstants
  alias Crit.Setup.AnimalApi
  alias Crit.Exemplars
  alias Crit.Setup.Schemas.Animal
  alias Crit.Setup.Schemas.ServiceGap
  alias Ecto.Datespan


  # This is a representation of how an animal-update form's parameters
  # would come to the controller if the user made no changes. Note
  # that the service gap array is returned as a map from (string)
  # index to the map representing the service gap.
  def unchanged_params(%Animal{} = animal) do
    base = 
      %{"in_service_datestring" => animal.in_service_datestring,
        "lock_version" => to_string(animal.lock_version),
        "name" => animal.name,
        "out_of_service_datestring" => animal.out_of_service_datestring,
        "institution" => @institution
       }

    service_gaps =
      [%ServiceGap{} | animal.service_gaps]
      |> Enum.with_index
      |> Enum.reduce(%{}, fn {sg, i}, acc ->
          Map.put(acc, to_string(i),
            if sg.id == nil do
              %{"id" => "",
                "in_service_datestring" => "",
                "out_of_service_datestring" => "",
                "reason" => "",
                "delete" => "false"
              }
            else
              %{"id" => to_string(sg.id),
                "in_service_datestring" => Datespan.first_to_string(sg.span),
                "out_of_service_datestring" => Datespan.last_to_string(sg.span),
                "reason" => sg.reason,
                "delete" => "false"
              }
            end)
          end)

    Map.put(base, "service_gaps", service_gaps)
  end

  

  def service_gap_n(%Animal{service_gaps: gaps}, n), do: Enum.at(gaps, n)

  def update_for_success(id, params) do
    {:ok, new_animal} =
      AnimalApi.update(to_string(id), params, @institution)
    new_animal
  end

  def update_for_error_changeset(id, params) do
    {:error, changeset} = AnimalApi.update(id, params, @institution)
    changeset
  end

  def updatable_animal_named(name) do
    id = Exemplars.Available.animal_id(name: name)
    AnimalApi.updatable!(id, @institution)
  end

  def dated(in_service, out_of_service) do
    [in_service_datestring: in_service,
     out_of_service_datestring: out_of_service]
    |> Exemplars.Available.animal_id
    |> AnimalApi.updatable!(@institution)
  end
  
  def params_except(%Animal{} = animal, overrides) do
    unchanged_params(animal)
    |> Map.merge(overrides)
  end
end
