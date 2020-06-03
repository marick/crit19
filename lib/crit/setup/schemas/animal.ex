defmodule Crit.Setup.Schemas.Animal do

  use Ecto.Schema
  alias Crit.Ecto.TrimmedString
  alias Crit.Setup.Schemas, as: S
  alias Ecto.Datespan
  # import Ecto.Changeset

  schema "animals" do
    field :name, TrimmedString
    field :span, Datespan
    field :available, :boolean, default: true
    field :lock_version, :integer, default: 1
    belongs_to :species, S.Species
    has_many :service_gaps, S.ServiceGap, foreign_key: :animal_id
    timestamps()
  end

  def preloads, do: [:species, :service_gaps]
end
