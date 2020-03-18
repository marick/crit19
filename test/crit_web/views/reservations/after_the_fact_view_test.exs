defmodule CritWeb.Reservations.AfterTheFactViewTest do
  use CritWeb.ConnCase, async: true
  alias CritWeb.Reservations.AfterTheFactView, as: View

  describe "the creation message" do
    test "no conflicts" do
      no_conflicts = %{}
      actual = View.describe_creation(no_conflicts)
      assert html_version(actual) =~ "ui positive"
    end

    @tag :skip
    test "service gap conflicts" do
      conflicts = %{service_gap_conflicts: "James and Fred"}
      actual = View.describe_creation(conflicts)
      assert html_version(actual) =~ "ui warning"
      assert html_version(actual) =~ "The reservation was created despite these oddities:"
      assert html_version(actual) =~ "James and Fred were supposed to be out of service on the reservation date."
    end

    test "use conflicts" do
    end
    
  end
end
