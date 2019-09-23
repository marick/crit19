defmodule Crit.Usables.Write.BulkAnimal do
  use Ecto.Schema
  import Ecto.Changeset
  import Crit.Usables.Write.ChangesetFlow
  alias Ecto.Datespan
  alias Crit.Usables.Write.{DateComputers, ServiceGapComputers, NameListComputers}


  embedded_schema do
    field :names, :string
    field :species_id, :integer
    field :start_date, :string
    field :end_date, :string
    field :timezone, :string

    field :computed_start_date, :date, virtual: true
    field :computed_end_date, :date, virtual: true
    field :computed_names, {:array, :string}, virtual: true
    field :computed_service_gaps, {:array, Datespan}, virtual: true
  end

  @required [:names, :species_id, :start_date, :end_date, :timezone]

  def changeset(bulk, attrs) do
    bulk
    |> cast(attrs, @required)
    |> validate_required(@required)
  end

  def compute_insertables(attrs) do
    given_all_form_values_are_present(changeset(%__MODULE__{}, attrs),
      fn changeset ->
        changeset
        |> NameListComputers.split_names
        |> DateComputers.start_and_end
        |> ServiceGapComputers.expand_start_and_end
      end)
  end
end
