defmodule Crit.Usables.Write.BulkAnimal do
  use Ecto.Schema
  import Ecto.Changeset
  import Pile.ChangesetFlow
  alias Ecto.Datespan
  alias Crit.Usables.Write.{DateComputers, ServiceGapComputers, NameListComputers,
                            Animal, ServiceGap}
  alias Crit.Usables.Write.ServiceGapComputers


  embedded_schema do
    field :names, :string
    field :species_id, :integer
    field :start_date, :string
    field :end_date, :string
    field :timezone, :string

    field :computed_start_date, :date, virtual: true
    field :computed_end_date, :date, virtual: true
    field :computed_names, {:array, :string}, virtual: true
    field :computed_service_gaps, {:array, ServiceGap}, virtual: true
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

  def changeset_to_changesets(%{valid?: true} = changeset) do
    changes = changeset.changes
    %{animal_changesets: animal_changesets(changes),
      service_gap_changesets: service_gap_changesets(changes.computed_service_gaps)
    }
  end

  defp animal_changesets(changes) do
    Enum.map(changes.computed_names, fn name ->
      Animal.changeset(name: name, species_id: changes.species_id)
    end)
  end

  defp service_gap_changesets(computed_service_gaps) do 
    Enum.map(computed_service_gaps, fn %{gap: gap, reason: reason} ->
      ServiceGap.changeset(gap: gap, reason: reason)
    end)
  end
end
