defmodule Crit.Usables.AnimalServiceGap do
  use Ecto.Schema
  alias Crit.Usables.{Animal, ServiceGap}

  schema "animal__service_gap" do
    belongs_to :animal, Animal
    belongs_to :service_gap, ServiceGap
  end
end

