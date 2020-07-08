defmodule Crit.Schemas.Timeslot do
  use Ecto.Schema
  
  schema "timeslots" do
    field :name, :string
    field :start, :time
    field :duration, :integer
  end
end
