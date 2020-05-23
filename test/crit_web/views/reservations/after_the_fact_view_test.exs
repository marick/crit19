defmodule CritWeb.Reservations.AfterTheFactViewTest do
  use CritWeb.ConnCase, async: true
  alias CritWeb.Reservations.AfterTheFactView, as: View

  describe "the creation message" do
    test "no conflicts" do
      no_conflicts = %{service_gap: [], use: [], rest_period: []}
      actual = View.describe_creation(no_conflicts)
      assert html_version(actual) =~ "ui positive"
    end

    test "service gap conflicts" do
      conflicts =
        %{service_gap: fake_animals(["James", "Fred", "Harry"]),
          use: [],
          rest_period: []}
      actual = View.describe_creation(conflicts)
      assert html_version(actual) =~ "ui warning"
      assert html_version(actual) =~ "The reservation was created despite these oddities:"
      assert html_version(actual) =~ "James, Fred, and Harry were supposed to be out of service on the reservation date."
    end

    test "use conflicts" do
      conflicts =
        %{service_gap: [], use: fake_animals(["Fred"]), rest_period: []}
      actual = View.describe_creation(conflicts)
      assert html_version(actual) =~ "ui warning"
      assert html_version(actual) =~ "The reservation was created despite these oddities:"
      assert html_version(actual) =~ "Fred was already reserved at the same time."
    end

    test "rest period conflicts" do
      conflicts = %{service_gap: [], use: [], rest_period: [
                     %{animal_name: "Bossie",
                       procedure_name: "embryo transfer",
                       dates: [~D[2020-05-18], ~D[2020-05-22]]}]}
      actual = View.describe_creation(conflicts)
      assert html_version(actual) =~ "ui warning"
      assert html_version(actual) =~ "The reservation was created despite these oddities:"
      assert html_version(actual) =~ "This use of Bossie for embryo transfer is too close to May 18 and May 22"
    end

    defp fake_animals(namelist) do
      for name <- namelist do
        %{name: name}
      end
    end
  end
end
