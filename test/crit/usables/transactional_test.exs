defmodule Crit.Usables.TransactionalTest do
  use Crit.DataCase
  alias Crit.Usables.Transactional
  alias Crit.Sql
  alias Crit.Usables.ServiceGap
  alias Ecto.Datespan

  @iso_date "2001-09-05"
  @date Date.from_iso8601!(@iso_date)

  describe "initial service gaps" do
    test "without an out-of-service date" do
      params = %{
        "start_date" => @iso_date,
        "end_date" => "never"
      }

      [gap_id] =
        Transactional.initial_service_gaps(params, @default_short_name)
        |> Repo.transaction
        |> gap_ids

      inserted = Sql.get(ServiceGap, gap_id, @default_short_name)

      assert inserted.gap == Datespan.infinite_down(@date, :exclusive)
    end
  end


  def gap_ids({:ok, %{gap_ids: gap_ids}}), do: gap_ids
end
