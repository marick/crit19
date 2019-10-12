defmodule Crit.Usables.Animal.Changeset do
  alias Crit.Usables.Animal
  import Ecto.Changeset


  def changeset(animal, attrs) do
    animal
    |> cast(attrs, [:name, :species_id, :lock_version])
    |> validate_required([:name, :species_id, :lock_version])
    |> constraint_on_name()
  end

  def changeset(fields) when is_list(fields) do
    changeset(%Animal{}, Enum.into(fields, %{}))
  end

  def edit_changeset(animal) do 
    change(animal)
  end

  def update_changeset(string_id, attrs) do
    id = String.to_integer(string_id)
    %Animal{id: id}
    |> cast(attrs, [:name])
    |> constraint_on_name()
    |> optimistic_lock(:lock_version)
  end
  
  defp constraint_on_name(changeset),
    do: unique_constraint(changeset, :name, name: "unique_available_names")
  
end  
