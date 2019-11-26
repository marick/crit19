defmodule Crit.X.ServiceGapX do
  @moduledoc """
  Shorthand functions for use in tests.
  """

  use Crit.Global.Default
  alias Crit.Usables.HiddenSchemas.ServiceGap
  alias Crit.Sql
  alias Crit.Exemplars.Available

  def insert(attrs) do
    %ServiceGap{}
    |> ServiceGap.changeset(attrs)
    |> Sql.insert!(@institution)
  end

  def attrs(in_service_date, out_of_service_date, reason, opts \\ []) do
    defaults = %{animal_id: Available.animal_id}
    optmap = Enum.into(opts, defaults)
    %{animal_id: optmap.animal_id,
      in_service_date: in_service_date,
      out_of_service_date: out_of_service_date,
      reason: reason}
  end

  def attrs(service_gap) do 
    %{id: service_gap.id,
      in_service_date: service_gap.in_service_date,
      out_of_service_date: service_gap.out_of_service_date,
      reason: service_gap.reason}
  end

  def get_and_complete(id) do
    ServiceGap
    |> Sql.get(id, @institution)
    |> ServiceGap.complete_fields
  end
end
