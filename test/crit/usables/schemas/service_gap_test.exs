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
      in_service_gap = Factory.in_service_gap
      {:ok, in_service_gap} =
        ServiceGap.in_service_gap(@date)
        |> Sql.insert(@institution)

      act_on = fn id, params ->
        ServiceGap.update_in_service_date(
          Minimal.service_gap(id), params, @institution)
      end
        
      [in_service_gap: in_service_gap, act_on: act_on]
    end

    test "in-service gaps can be updated",
      %{in_service_gap: original, act_on: act_on} do

      assert {:ok, _} =
        act_on.(original.id, %{"in_service_date" => @later_iso_date})
      
      assert fetched = Sql.get(ServiceGap, original.id, @institution)
      assert fetched.gap == Datespan.strictly_before(@later_date)
      assert fetched.reason == original.reason
    end

    test "a bad in-service gap date produces the usual sort of changeset",
      %{in_service_gap: original, act_on: act_on} do

      assert {:error, changeset} =
        act_on.(original.id, %{"in_service_date" => "bogus"})

      assert "is invalid" in errors_on(changeset).in_service_date

      # No change.
      assert fetched = Sql.get(ServiceGap, original.id, @institution)
      assert fetched.gap == original.gap
    end
    
  end
end
