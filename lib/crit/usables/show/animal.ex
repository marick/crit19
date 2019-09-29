defmodule Crit.Usables.Show.Animal do
  alias Crit.Usables.Read
  alias Ecto.Datespan

  defstruct id: nil, name: nil, species_name: nil, species_id: nil,
    in_service_date: nil,
    out_of_service_date: nil

  def convert(
    %Read.Animal{
      id: animal_id,
      name: name,
      species: %{name: species_name},
      service_gaps: gaps,
    }) do

    timespans = Enum.map(gaps, &(&1.gap))

    in_service_date =
      timespans
      |> Enum.find(&Datespan.infinite_down?/1)

    in_service_iso = Date.to_iso8601(in_service_date.last)

    out_of_service_iso = 
      case Enum.find(timespans, &Datespan.infinite_up?/1) do
        nil -> "never"
        date -> Date.to_iso8601(date.first)
      end

    %__MODULE__{
      id: animal_id,
      name: name,
      species_name: species_name,
      in_service_date: in_service_iso,
      out_of_service_date: out_of_service_iso
    }
  end

end
