defmodule CritWeb.ViewModels.Procedure.Creation do
  use Ecto.Schema
  # use Crit.Global.Constants
  # alias Crit.Setup.InstitutionApi
  import Ecto.Changeset

  embedded_schema do
    field :index, :integer
    field :name, :string, default: ""
    field :species_ids, {:array, :id}
  end

  @required [:name, :species_ids]

  def starting_changeset() do
    %__MODULE__{}
    |> cast(%{}, @required)
    |> validate_required(@required)
  end

end
