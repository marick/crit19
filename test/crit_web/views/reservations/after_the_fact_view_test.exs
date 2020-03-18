defmodule CritWeb.Reservations.AfterTheFactViewTest do
  use CritWeb.ConnCase, async: true
  alias CritWeb.Reservations.AfterTheFactView, as: View

  describe "the creation message" do
    test "no conflicts" do
      no_conflicts = %{service_gap: [], use: []}
      actual = View.describe_creation(no_conflicts)
      assert html_version(actual) =~ "ui positive"
    end

    test "service gap conflicts" do
      conflicts = %{service_gap: fake_animals(["James", "Fred"]), use: []}
      actual = View.describe_creation(conflicts)
      assert html_version(actual) =~ "ui warning"
      assert html_version(actual) =~ "The reservation was created despite these oddities:"
      assert html_version(actual) =~ "James and Fred were supposed to be out of service on the reservation date."
    end

    test "use conflicts" do
      conflicts = %{service_gap: [], use: fake_animals(["Fred"])}
      actual = View.describe_creation(conflicts)
      assert html_version(actual) =~ "ui warning"
      assert html_version(actual) =~ "The reservation was created despite these oddities:"
      assert html_version(actual) =~ "Fred was already reserved at the same time."
    end

    defp fake_animals(namelist) do
      for name <- namelist do
        %{name: name}
      end
    end
  end
end
