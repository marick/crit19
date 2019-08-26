defmodule Crit.Usables.ScheduledUnavailability do
  use Ecto.Schema
  alias Crit.Usables.Animal
  alias Ecto.Timespan

  schema "scheduled_unavailabilities" do
    belongs_to :animal, Animal
    field :timespan, Timespan
    field :reason, :string

    timestamps()
  end
end

