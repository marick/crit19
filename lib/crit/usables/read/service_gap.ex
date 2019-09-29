defmodule Crit.Usables.Read.ServiceGap do
  use Ecto.Schema
  alias Ecto.Datespan

  schema "service_gaps" do
    field :gap, Datespan
    field :reason, :string
  end

end
