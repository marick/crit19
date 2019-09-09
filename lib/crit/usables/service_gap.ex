defmodule Crit.Usables.ServiceGap do
  use Ecto.Schema
  alias Crit.Usables.Animal
  alias Ecto.Datespan

  schema "service_gaps" do
    field :gap, Datespan
    field :reason, :string
  end
end

