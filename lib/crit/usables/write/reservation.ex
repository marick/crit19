defmodule Crit.Usables.Write.Reservation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Timespan

  schema "reservation" do
    field :timespan, Timespan
    field :animal_ids, {:array, :integer}
    field :procedure_ids, {:array, :integer}


    field :start_date, :date, virtual: true
    field :start_time, :time, virtual: true
    field :minutes, :integer, virtual: true
    timestamps()
  end

  @required [:start_date, :start_time, :minutes, :animal_ids, :procedure_ids]

  def changeset(reservation, attrs) do
    reservation
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
end
