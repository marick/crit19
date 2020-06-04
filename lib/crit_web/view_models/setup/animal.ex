defmodule CritWeb.ViewModels.Setup.Animal do
  use Ecto.Schema
  alias Crit.Ecto.TrimmedString
  alias CritWeb.ViewModels.Setup, as: ViewModels
#  alias Ecto.Datespan
  # import Ecto.Changeset
  # alias Crit.FieldConverters.ToSpan
  # alias Crit.Common
  alias CritWeb.ViewModels.FieldFillers.ToWeb

  @primary_key false   # I do this to emphasize that ID not be forgotten.
  embedded_schema do
    field :id, :integer
    # The fields below are the true fields in the table.
    field :name, TrimmedString
    field :available, :boolean
    field :lock_version, :integer
    
    # Virtual fields used for displays or forms presented to a human
    field :institution, :string
    field :in_service_datestring, :string
    field :out_of_service_datestring, :string
    field :species_name, :string

    field :service_gaps, {:array, ViewModels.ServiceGap}
  end

  def from_ecto(sources, institution) when is_list(sources), 
    do: (for s <- sources, do: from_ecto(s, institution))

  def from_ecto(source, institution) do
    %{EnumX.pour_into(source, __MODULE__) |
      species_name: source.species.name,
      institution: institution
    }
    |> ToWeb.service_datestrings(source.span)

    # updatable_service_gaps = 
    #   Enum.map(target.service_gaps,
    #     &(Schemas.ServiceGap.put_updatable_fields &1, institution))
    # %{ target |
    #    species_name: target.species.name, 
    #    service_gaps: updatable_service_gaps,
    #    institution: institution
    # }
  end
end
