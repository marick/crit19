defmodule Crit.X.AnimalX do
  @moduledoc """
  Shorthand functions for use in tests.
  """

  use Crit.Global.Default
  use Crit.Global.Constants
  alias Crit.Usables.AnimalApi
  alias Crit.Exemplars
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

  def update_for_success(id, params) do
    {:ok, new_animal} =
      AnimalApi.update(to_string(id), params, @institution)
    new_animal
  end

  def update_for_error(id, params) do
    {:error, changeset} = AnimalApi.update(id, params, @institution)
    errors_on(changeset)
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


  IO.puts "Don't have two copies of `errors_on`."

  defp errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
  
end
