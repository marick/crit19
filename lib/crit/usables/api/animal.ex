defmodule Crit.Usables.Api.Animal do
  alias Crit.Usables.Read

  defstruct id: nil, name: nil, species_name: nil, species_id: nil

  def convert(
    %Read.Animal{
      id: animal_id,
      name: name,
      species: %{name: species_name}
    }) do
  
    %__MODULE__{
      id: animal_id,
      name: name,
      species_name: species_name,
    }
  end

end
