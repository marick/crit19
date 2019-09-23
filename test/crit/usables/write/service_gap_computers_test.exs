defmodule Crit.Usables.Write.ServiceGapComputersTest do
  use Ecto.Schema
  use Crit.DataCase
  alias Crit.Usables.Write.ServiceGapComputers
  alias Ecto.Datespan
  alias Ecto.Changeset

  embedded_schema do
    field :computed_start_date, :date, virtual: true
    field :computed_end_date, :date, virtual: true
    field :computed_service_gaps, {:array, Datespan}, virtual: true
  end
  
  @iso_date "2001-09-05"
  @date Date.from_iso8601!(@iso_date)

  @later_iso_date "2200-09-05"
  @later_date Date.from_iso8601!(@later_iso_date)

  def so_far(opts \\ []) do
    default = %{}
    Changeset.change(%__MODULE__{}, Enum.into(opts, default))
  end
  
  describe "changeset: handling the service gaps" do
    test "two gaps" do
      changeset = 
        so_far(computed_start_date: @date, computed_end_date: @later_date)
        |> ServiceGapComputers.expand_start_and_end

      assert changeset.valid?
      assert [in_service, out_of_service] = changeset.changes.computed_service_gaps

      assert_strictly_before(in_service.gap, @date)
      assert in_service.reason == ServiceGapComputers.before_service_reason()

      assert_date_and_after(out_of_service.gap, @later_date)
      assert out_of_service.reason == ServiceGapComputers.after_service_reason()
    end

    test "one gap" do
      changeset = 
        so_far(computed_start_date: @date, computed_end_date: :missing)
        |> ServiceGapComputers.expand_start_and_end

      assert changeset.valid?
      assert [in_service] = changeset.changes.computed_service_gaps

      assert_strictly_before(in_service.gap, @date)
      assert in_service.reason == ServiceGapComputers.before_service_reason()
    end
  end
end  
