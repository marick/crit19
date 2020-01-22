defmodule Crit.Setup.Schemas.TimeSlot do
  use Ecto.Schema
  alias Crit.Setup.Schemas.Institution

  @schema_prefix "global"
  
  schema "time_slots" do
    belongs_to :institution, Institution
    field :name, :string
    field :start, :time
    field :duration, :integer
  end
end
