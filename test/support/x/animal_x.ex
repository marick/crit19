defmodule Crit.X.AnimalX do
  @moduledoc """
  Shorthand functions for use in tests.
  """

  use Crit.Global.Default
  use Crit.Global.Constants
  alias Crit.Usables.Schemas.Animal
  alias Crit.Usables.Schemas.ServiceGap
  alias Crit.X.ServiceGapX

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
      service_gaps: Enum.map(animal.service_gaps, &ServiceGapX.attrs/1)
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

  def service_gap_n(%Animal{service_gaps: gaps}, n), do: Enum.at(gaps, n)
end
