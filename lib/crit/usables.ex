defmodule Crit.Usables do
  alias Crit.Usables.Animal

  
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

  # @doc """
  # Gets a single animal.

  # Raises `Ecto.NoResultsError` if the Animal does not exist.

  # ## Examples

  #     iex> get_animal!(123)
  #     %Animal{}

  #     iex> get_animal!(456)
  #     ** (Ecto.NoResultsError)

  # """
  # def get_animal!(id), do: Repo.get!(Animal, id)

  def create_animal(_attrs, _institution) do
    {:ok, %Animal{}}
    # |> Animal.changeset(attrs)
    # |> Sql.insert(institution)
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

  def repeated_animal_changeset(_params) do
  end
end
