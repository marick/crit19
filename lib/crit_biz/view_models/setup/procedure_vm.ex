defmodule CritBiz.ViewModels.Setup.Procedure do
  use Ecto.Schema
  alias Crit.Schemas
  alias Crit.Setup.InstitutionApi
  alias Crit.Ecto.TrimmedString
  alias CritBiz.ViewModels.Setup, as: VM

  @primary_key false   # I do this to emphasize `id` is just another field
  embedded_schema do
    field :id, :id
    field :name, TrimmedString
    field :species_name, :string
    field :frequency_name, :string
  end

  def fields(), do: __schema__(:fields)

  # ----------------------------------------------------------------------------
  
  def fetch(:one_for_summary, id, institution) do
    Schemas.Procedure.Get.one_by_id(id, institution)
    |> lift(institution)
  end

  def lift(sources, institution) when is_list(sources), 
    do: (for s <- sources, do: lift(s, institution))

  def lift(source, institution) do
    species_name =
      InstitutionApi.species_name(source.species_id, institution)
    frequency_name =
      InstitutionApi.procedure_frequency_name(source.frequency_id, institution)

    %{EnumX.pour_into(source, VM.Procedure) |
      species_name: species_name,
      frequency_name: frequency_name
    }
  end

  # ----------------------------------------------------------------------------
  

  def to_view_model(%Schemas.Procedure{} = p, institution) do
    species_name = InstitutionApi.species_name(p.species_id, institution)
    frequency_name = InstitutionApi.procedure_frequency_name(p.frequency_id, institution)
    %__MODULE__{name: p.name,
                species_name: species_name,
                frequency_name: frequency_name}
  end
end
