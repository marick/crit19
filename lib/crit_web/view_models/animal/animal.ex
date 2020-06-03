defmodule CritWeb.ViewModels.Animal.Animal do
  use Ecto.Schema
  alias Crit.Ecto.TrimmedString
  alias Crit.Setup.Schemas
  alias Ecto.Datespan
  # import Ecto.Changeset
  # alias Crit.FieldConverters.ToSpan
  # alias Crit.Common
  alias Crit.FieldConverters.FromSpan

  schema "animals" do
    # The fields below are the true fields in the table.
    field :name, TrimmedString
    field :span, Datespan
    field :available, :boolean, default: true
    field :lock_version, :integer, default: 1
    
    # Virtual fields used for displays or forms presented to a human
    field :institution, :string
    field :in_service_datestring, :string
    field :out_of_service_datestring, :string
    # Since the species can't be changed, a form could be populated
    # via species.name, but I have a slight preference for
    # having a "flat" interface that the form uses.
    field :species_name, :string

    # Associations
    has_many :service_gaps, Schemas.ServiceGap, foreign_key: :animal_id
    belongs_to :species, Schemas.Species
  end

  def from_ecto(source, institution) do
    alias S.Animal, as: Target

    target = 
      EnumX.pour_into(source, Target)
      |> FromSpan.expand

    updatable_service_gaps = 
      Enum.map(target.service_gaps,
        &(Schemas.ServiceGap.put_updatable_fields &1, institution))
    %{ target |
       species_name: target.species.name, 
       service_gaps: updatable_service_gaps,
       institution: institution
    }
  end
end
