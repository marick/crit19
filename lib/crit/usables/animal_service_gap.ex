defmodule Crit.Usables.AnimalServiceGap do
  use Ecto.Schema
  alias Crit.Usables.{Animal, ServiceGap}

  schema "animal__service_gap" do
    belongs_to :animal, Animal
    belongs_to :service_gap, ServiceGap
  end

  def new(animal_id, service_gap_id),
    do: %__MODULE__{animal_id: animal_id, service_gap_id: service_gap_id}

  def cross_product(animal_ids, service_gap_ids) do
    for a_id <- animal_ids, sg_id <- service_gap_ids,
      do: new(a_id, sg_id)
  end

  defmodule TxPart do
    use Ecto.MegaInsertion,
      individual_result_prefix: :asg,
      idlist_result_prefix: :unused___allow_this_to_be_optional
  end
end

