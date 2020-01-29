defmodule CritWeb.Reservations.AfterTheFact.AnimalData do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Common


  embedded_schema do
    field :transaction_key, :string
    field :chosen_animal_ids, {:array, :integer}
  end

  @fields [:transaction_key, :chosen_animal_ids]

  def changeset(given_attrs) do
    attrs = Common.make_id_array(given_attrs, "chosen_animal_ids")

    %__MODULE__{}
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
