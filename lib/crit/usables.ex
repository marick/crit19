defmodule Crit.Usables do
  alias Crit.Sql
  alias Crit.Usables.{Animal, ServiceGap, AnimalServiceGap}
  alias Ecto.Multi
  alias Crit.Sql

  
  # @moduledoc """
  # The Usables context.
  # """

  # import Ecto.Query, warn: false
  # alias Crit.Repo

  # alias Crit.Usables.Animal

  # @doc """
  # Returns the list of animals.

  # ## Examples

  #     iex> list_animals()
  #     [%Animal{}, ...]

  # """
  # def list_animals do
  #   Repo.all(Animal)
  # end


  def get_complete_animal(id, institution) do
    case id |> Animal.Query.complete |> Sql.one(institution) do
      nil ->
        raise KeyError, "No animal id #{id}"
      animal ->
        animal
    end
  end

  def with_institution_timezone(attrs, _institution),
    do: Map.put(attrs, "timezone", "America/Chicago")

  def create_animal(attrs, institution) do
    adjusted_attrs = attrs |> with_institution_timezone(institution)
    {:ok, animal_changesets} = Animal.creational_changesets(adjusted_attrs)
    service_gap_changesets = ServiceGap.initial_changesets(adjusted_attrs)

    animal_multi =
      Animal.TxPart.multi_collecting_ids(animal_changesets, institution)
    service_gap_multi =
      ServiceGap.TxPart.multi_collecting_ids(service_gap_changesets, institution)
    connector_function =
      AnimalServiceGap.TxPart.make_connections(institution)

    Multi.new
    |> Multi.append(animal_multi)
    |> Multi.append(service_gap_multi)
    |> Multi.merge(connector_function)
    |> Sql.transaction(institution)
  end

  # @doc """
  # Updates a animal.

  # ## Examples

  #     iex> update_animal(animal, %{field: new_value})
  #     {:ok, %Animal{}}

  #     iex> update_animal(animal, %{field: bad_value})
  #     {:error, %Ecto.Changeset{}}

  # """
  # def update_animal(%Animal{} = animal, attrs) do
  #   animal
  #   |> Animal.changeset(attrs)
  #   |> Repo.update()
  # end

  # @doc """
  # Deletes a Animal.

  # ## Examples

  #     iex> delete_animal(animal)
  #     {:ok, %Animal{}}

  #     iex> delete_animal(animal)
  #     {:error, %Ecto.Changeset{}}

  # """
  # def delete_animal(%Animal{} = animal) do
  #   Repo.delete(animal)
  # end

  def change_animal(%Animal{} = animal) do
    Animal.changeset(animal, %{})
  end
end
