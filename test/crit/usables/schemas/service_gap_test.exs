defmodule Crit.Usables.Schemas.ServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.Schemas.ServiceGap
  alias Ecto.Datespan
  alias Crit.Sql
  alias Crit.Exemplars.Minimal

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

  describe "updating a gap used as the in-service date" do
    setup do
      {:ok, in_service_gap} =
        ServiceGap.in_service_gap(@date)
        |> Sql.insert(@institution)
      
      [in_service_gap: in_service_gap]
    end

    test "in-service gaps can be updated",
      %{in_service_gap: original} do

      assert changeset =
        ServiceGap.update_changeset(original, %{"in_service_date" => @later_iso_date})
      
      assert changeset.valid?
      assert changeset.changes.gap == Datespan.strictly_before(@later_date)
    end

    test "a bad in-service gap date produces the usual sort of changeset",
      %{in_service_gap: original} do

      assert changeset =
        ServiceGap.update_changeset(original, %{"in_service_date" => "bad date"})
      
      refute changeset.valid?
      assert errors_on(changeset).in_service_date
    end
  end
end
