defmodule Crit.Extras.ServiceGapT do
  @moduledoc """
  Shorthand functions for use in tests.
  """

  use Crit.Global.Default
  alias Crit.Usables.Schemas.{Animal,ServiceGap}
  alias Crit.Sql
  alias Crit.Exemplars.Available

  def insert(attrs) do
    %ServiceGap{}
    |> ServiceGap.changeset(attrs)
    |> Sql.insert!(@institution)
  end

  def make_changesets(animal, attrs) do
    Animal.update_changeset(animal, attrs).changes.service_gaps
  end

  def update_animal_for_service_gaps(animal, attrs) do 
    {:ok, %Animal{service_gaps: gaps}} = 
      animal
      |> Animal.update_changeset(attrs)
      |> Sql.update(@institution)
    gaps
  end

  def attrs(in_service_datestring, out_of_service_datestring, reason, opts \\ []) do
    defaults = %{animal_id: Available.animal_id}
    optmap = Enum.into(opts, defaults)
    %{animal_id: optmap.animal_id,
      in_service_datestring: in_service_datestring,
      out_of_service_datestring: out_of_service_datestring,
      reason: reason,
      delete: false
    }
  end

  def attrs(service_gap) do 
    %{id: service_gap.id,
      in_service_datestring: service_gap.in_service_datestring,
      out_of_service_datestring: service_gap.out_of_service_datestring,
      reason: service_gap.reason,
      delete: service_gap.delete
    }
  end

  def get_updatable(id) do
    ServiceGap
    |> Sql.get(id, @institution)
    |> ServiceGap.put_updatable_fields
  end
end
