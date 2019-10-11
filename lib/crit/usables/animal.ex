defmodule Crit.Usables.Animal do

  @doc """
  I'd rather call this module `Animal.Schema` but then having foreign
  keys like `:animal_id` becomes awkward.
  """
  use Ecto.Schema
  alias Crit.Ecto.TrimmedString
  alias Crit.Usables.Write

  schema "animals" do
    # The fields below are the true fields in the table.
    field :name, TrimmedString
    field :available, :boolean, default: true
    field :lock_version, :integer, default: 1
    # field :species_id is as well, but it's created by `belongs_to` below.
    timestamps()

    belongs_to :species, Write.Species
    many_to_many :service_gaps, Write.ServiceGap, join_through: "animal__service_gap"

    field :species_name, :string, virtual: true
    field :in_service_date, :string, virtual: true
    field :out_of_service_date, :string, virtual: true
  end
end
