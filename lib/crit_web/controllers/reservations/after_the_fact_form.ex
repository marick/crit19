defmodule CritWeb.Reservations.AfterTheFactForm do
  use Ecto.Schema
  import Ecto.Changeset
  # import Pile.ChangesetFlow
  # alias Crit.FieldConverters.{ToSpan, ToNameList}
  # alias Ecto.Datespan


  embedded_schema do
    field :species_id, :integer
    field :date, :date
    field :date_showable_date, :string
    field :part_of_day_id, :string
  end

  @form_fields [:species_id, :date, :part_of_day]

  def changeset_1 do
    change(%__MODULE__{})
  end

end
