defmodule Crit.Usables.Write.ServiceGap do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Datespan

  schema "service_gaps" do
    field :gap, Datespan
    field :reason, :string
  end

  @required [:gap, :reason]

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end

  def changeset(fields) when is_list(fields) do
    changeset(%__MODULE__{}, Enum.into(fields, %{}))
  end
end