defmodule CritWeb.ViewModels.Procedure.Show do
  use Ecto.Schema
  alias Crit.Setup.Schemas.Procedure
  alias Crit.Setup.InstitutionApi

  embedded_schema do
    field :name, :string
    field :species_name, :string
    field :frequency_name, :string
  end

  def to_view_model(%Procedure{} = p, institution) do
    species_name = InstitutionApi.species_name(p.species_id, institution)
    frequency_name = InstitutionApi.procedure_frequency_name(p.frequency_id, institution)
    %__MODULE__{name: p.name,
                species_name: species_name,
                frequency_name: frequency_name}
  end
end
