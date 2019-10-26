defmodule Crit.Usables.Schemas.BulkAnimal do
  use Ecto.Schema
  import Ecto.Changeset
  import Pile.ChangesetFlow
  # alias Crit.Usables.AnimalApi
  alias Crit.Usables.FieldConverters.{ToDate, ToNameList}
  alias Crit.Usables.Schemas.Animal


  embedded_schema do
    # user-supplied fields
    field :names, :string
    field :species_id, :integer
    field :in_service_datestring, :string
    field :out_of_service_datestring, :string
    field :timezone, :string   # strictly, this is filled in by calling code,
                               # not by a user or browser.

    # computed fields
    field :in_service_date, :date
    field :out_of_service_date, :date
    field :computed_names, {:array, :string}
  end

  @form_fields [:names, :species_id, :timezone,
                :in_service_datestring, :out_of_service_datestring]

  def changeset(bulk, attrs) do
    bulk
    |> cast(attrs, @form_fields)
    |> validate_required(@form_fields)
  end

  def compute_insertables(attrs) do
    given_all_form_values_are_present(changeset(%__MODULE__{}, attrs),
      fn changeset ->
        changeset
        |> ToNameList.split_names(from: :names, to: :computed_names)
        |> ToDate.put_service_dates
      end)
  end

  def changeset_to_changesets(%{changes: changes}) do
    base_attrs = %{species_id: changes.species_id,
                   in_service_date: changes.in_service_date,
                   out_of_service_date: changes[:out_of_service_date]
                  }
    
    one_animal = fn name ->
      Animal.creation_changeset(Map.put(base_attrs, :name, name))
    end

    Enum.map(changes.computed_names, one_animal)
  end

  # defp animal_changesets(changes) do
  #   Enum.map(changes.computed_names, fn name ->
  #     AnimalApi.changeset(name: name, species_id: changes.species_id)
  #   end)
  # end

end
