defmodule Crit.Usables.FieldConverters.ToServiceGapTest do
  use Ecto.Schema
  use Crit.DataCase
  alias Crit.Usables.FieldConverters.ToServiceGap
  alias Ecto.Datespan
  alias Ecto.Changeset

  embedded_schema do
    field :computed_start_date, :date, virtual: true
    field :computed_end_date, :date, virtual: true
    field :computed_service_gaps, {:array, Datespan}, virtual: true
  end

  def make_changeset_with_computed_dates(opts \\ []) do
    default = %{}
    Changeset.change(%__MODULE__{}, Enum.into(opts, default))
  end
  
  describe "converting dates into service gaps" do
    test "two gaps because there is an end date" do
      actual =
        [computed_start_date: @date, computed_end_date: @later_date]
        |> make_changeset_with_computed_dates
        |> ToServiceGap.expand_start_and_end

      assert actual.valid?
      assert [in_service, out_of_service] = actual.changes.computed_service_gaps

      assert_strictly_before(in_service.gap, @date)
      assert in_service.reason == ToServiceGap.before_service_reason()

      assert_date_and_after(out_of_service.gap, @later_date)
      assert out_of_service.reason == ToServiceGap.after_service_reason()
    end

    test "one gap because there's no specific end date" do
      actual =
        [computed_start_date: @date, computed_end_date: :missing]
        |> make_changeset_with_computed_dates
        |> ToServiceGap.expand_start_and_end

      assert actual.valid?
      assert [in_service] = actual.changes.computed_service_gaps

      assert_strictly_before(in_service.gap, @date)
      assert in_service.reason == ToServiceGap.before_service_reason()
    end
  end
end  
