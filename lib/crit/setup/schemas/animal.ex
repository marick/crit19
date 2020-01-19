defmodule Crit.Setup.Schemas.Animal do

  @doc """
  I'd rather call this module `Animal.Schema` but then having foreign
  keys like `:animal_id` becomes awkward.
  """
  use Ecto.Schema
  alias Crit.Ecto.TrimmedString
  alias Crit.Setup.HiddenSchemas.Species
  alias Crit.Setup.Schemas.ServiceGap
  alias Ecto.Datespan
  import Ecto.Changeset
  alias Crit.FieldConverters.ToSpan
  alias Crit.Common

  schema "animals" do
    # The fields below are the true fields in the table.
    field :name, TrimmedString
    field :span, Datespan
    field :available, :boolean, default: true
    field :lock_version, :integer, default: 1
    
    # field :species_id is as well, but it's created by `belongs_to` below.
    timestamps()

    # Associations
    belongs_to :species, Species
    has_many :service_gaps, ServiceGap

    # Virtual fields used for displays or forms presented to a human
    field :institution, :string, virtual: true
    field :in_service_datestring, :string, virtual: true
    field :out_of_service_datestring, :string, virtual: true
    # Since the species can't be changed, a form could be populated
    # via species.name, but I have a slight preference for
    # having a "flat" interface that the form uses.
    field :species_name, :string, virtual: true
  end

  # This changeset comes from bulk creation with the datestrings
  # already turned into a span. This is perilous - rethink?
  def from_bulk_creation_changeset(attrs) do
    required = [:name, :species_id, :lock_version, :span]
    %__MODULE__{}
    |> cast(attrs, required)
    |> validate_required(required)
    |> constraint_on_name()
  end

  def form_changeset(animal) do
    animal
    |> prepend_empty_service_gap
    |> change
  end

  def prepend_empty_service_gap(animal) do
    Map.put(animal, :service_gaps, [%ServiceGap{} | animal.service_gaps])
  end
    

  def update_changeset(struct, given_attrs) do
    attrs =
      Common.filter_out_unstarted_subforms(
        given_attrs,
        "service_gaps",
        ServiceGap.unstarted_form_sentinels)
    required = [:name, :lock_version]
    struct
    |> cast(attrs, required)
    |> validate_required(required)
    |> ToSpan.synthesize(attrs)
    |> cast_assoc(:service_gaps)
    |> constraint_on_name()
    |> optimistic_lock(:lock_version)
  end

  defp constraint_on_name(changeset),
    do: unique_constraint(changeset, :name, name: "unique_available_names")
end
