defmodule Spikes.Use do
  use Ecto.Schema

  schema "uses" do
    belongs_to :animal, Spikes.Animal
    belongs_to :procedure, Spikes.Procedure
    belongs_to :reservation, Spikes.Reservation
    timestamps()
  end
end
