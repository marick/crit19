defmodule Crit.Usables.AnimalServiceGap do
  use Ecto.Schema
  alias Crit.Usables.{Animal, ServiceGap}

  schema "animal__service_gap" do
    belongs_to :animal, Animal
    belongs_to :service_gap, ServiceGap
  end

  def new(animal_id, service_gap_id),
    do: %__MODULE__{animal_id: animal_id, service_gap_id: service_gap_id}
end

