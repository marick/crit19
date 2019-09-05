defmodule Crit.Usables.ScheduledUnavailability do
  use Ecto.Schema
  alias Crit.Usables.Animal
  alias Ecto.Datespan

  schema "scheduled_unavailabilities" do
    belongs_to :animal, Animal
    field :datespan, Datespan
    field :reason, :string

    timestamps()
  end
end

