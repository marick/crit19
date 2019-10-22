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
        %ServiceGap{gap: Datespan.strictly_before(@date), reason: "in service"}
        |> Sql.insert(@institution)

      act_on = fn id, params ->
        ServiceGap.update_in_service_date(
          Minimal.service_gap(id), params, @institution)
      end
        
      [in_service_gap: in_service_gap, act_on: act_on]
    end

    test "in-service gaps can be updated",
      %{in_service_gap: service_gap, act_on: act_on} do

      assert {:ok, _} =
        act_on.(service_gap.id, %{"in_service_date" => @later_iso_date})
      
      assert fetched = Sql.get(ServiceGap, service_gap.id, @institution)
      assert fetched.gap == Datespan.strictly_before(@later_date)
      assert fetched.reason == service_gap.reason
    end
  end
end
