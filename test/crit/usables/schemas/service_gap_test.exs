defmodule Crit.Usables.Schemas.ServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.Schemas.ServiceGap
  alias Ecto.Datespan
  alias Ecto.Changeset
  alias Crit.Sql

  describe "dividing by type" do
    test "has in-service and out-of-service date" do
      in_service = %ServiceGap{gap: Datespan.strictly_before(@date),
                               reason: "in service"}
      out_of_service = %ServiceGap{gap: Datespan.date_and_after(@later_date),
                                   reason: "out of service"}

      result = ServiceGap.separate_kinds([out_of_service, in_service])
      assert result.in_service == in_service
      assert result.out_of_service == out_of_service
      assert result.others == []
    end


    test "has only an in-service date" do
      in_service = %ServiceGap{gap: Datespan.strictly_before(@date),
                               reason: "in service"}

      result = ServiceGap.separate_kinds([in_service])
      assert result.in_service == in_service
      assert result.out_of_service == nil
      assert result.others == []
    end
  end

  test "service gaps can be updated" do
    {:ok, service_gap} =
      %ServiceGap{gap: Datespan.strictly_before(@date), reason: "in service"}
      |> Sql.insert(@institution)

    params = %{"in_service_date" => @later_iso_date}
    changeset = ServiceGap.update_changeset(%ServiceGap{id: service_gap.id}, params)

    Sql.update(changeset, @institution) |> IO.inspect


  end

end
