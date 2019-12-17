defmodule Crit.Extras.AnimalT do
  @moduledoc """
  Shorthand functions for use in tests.
  """

  use Crit.Global.Default
  use Crit.Global.Constants
  alias Crit.Usables.AnimalApi
  alias Crit.Exemplars
  alias Crit.Usables.Schemas.Animal
  alias Crit.Usables.Schemas.ServiceGap
  alias Crit.Extras.ServiceGapT

  def attrs(%Animal{} = animal) do
    out_string = if animal.out_of_service_date do
      Date.to_iso8601(animal.out_of_service_date)
    else
      @never
    end
    
    %{id: animal.id,
      name: animal.name,
      in_service_date: Date.to_iso8601(animal.in_service_date),
      out_of_service_date: out_string,
      lock_version: animal.lock_version,
      service_gaps: Enum.map(animal.service_gaps, &ServiceGapT.attrs/1)
    }
  end
    

  def attrs_plus(animal, replacements) do
    Enum.reduce(replacements, attrs(animal), fn {field, value}, acc ->
      Map.put(acc, field, value)
    end)
  end

  def attrs_plus_service_gap(animal, new_gap) do
    new_gaps = animal.service_gaps ++ [struct(ServiceGap, new_gap)]
    new_animal = %{animal | service_gaps: new_gaps}
    attrs(new_animal)
  end

  # This is like `attrs`, except it produces something closer to form parameters:
  # 1. map keys are strings, not atoms.
  # 2. The service gap array is returned as a map from (string) index to
  #    the map representing the service gap.
  # The latter, especially, is overkill, since the current animal-controller
  # flattens the map anyway.
  def params(%Animal{} = animal) do
    base = 
      %{"in_service_datestring" => animal.in_service_datestring,
        "lock_version" => to_string(animal.lock_version),
        "name" => animal.name,
        "out_of_service_datestring" => animal.out_of_service_datestring,
       }
    service_gaps =
      Enum.reduce(Enum.with_index(animal.service_gaps), %{}, fn {sg, i}, acc ->
        Map.put(acc,
          to_string(i),
          %{"id" => to_string(sg.id),
            "in_service_date" => Date.to_iso8601(sg.span.first),
            "out_of_service_date" => Date.to_iso8601(sg.span.last),
            "reason" => sg.reason,
            "delete" => "false"
          })
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
  
  def params_except(%Animal{} = animal, overrides) do
    from_animal =
      %{"name" => animal.name,
        "lock_version" => animal.lock_version,
        "in_service_datestring" => animal.in_service_datestring,
        "out_of_service_datestring" => animal.out_of_service_datestring
       }
    Map.merge(from_animal, overrides)
  end
end
