defmodule CritWeb.Reservations.ReservationForm do
  use Ecto.Schema
  import Ecto.Changeset
  # import Pile.ChangesetFlow
  # alias Crit.FieldConverters.{ToSpan, ToNameList}
  # alias Ecto.Datespan


  embedded_schema do
    field :species_id, :integer
    field :date, :date
    field :part_of_day, :string
  end

  @form_fields [:species_id, :date, :part_of_day]

  def initial do
    change(%__MODULE__{})
  end

  def changeset(bulk, attrs) do
    bulk
    |> cast(attrs, @form_fields)
    |> validate_required(@form_fields)
  end
end
