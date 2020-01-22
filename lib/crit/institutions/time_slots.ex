defmodule Crit.Global.TimeSlot do
  use Ecto.Schema
  alias Crit.Global.Institution

  @schema_prefix "global"
  
  schema "time_slots" do
    belongs_to :institution, Institution
    field :name, :string
    field :start, :time
    field :duration, :integer
  end
end
