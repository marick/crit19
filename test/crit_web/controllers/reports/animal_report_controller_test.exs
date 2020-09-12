defmodule CritWeb.Reports.AnimalReportControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.Reports.AnimalReportController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Servers.Institution
  alias Crit.Exemplars.ReservationFocused

  setup :logged_in_as_reservation_manager

  @in_this_month ~N[2020-03-04 08:23:34.00]
  @in_last_month ~D[2020-02-29]

  def given_now(moment) do 
    timezone = Institution.timezone(@institution)
    in_this_month = DateTime.from_naive!(moment, timezone)
    given DateTime.now, [^timezone], do: {:ok, in_this_month}
  end

  setup do
    given_now(@in_this_month)
    ReservationFocused.reserved!(@bovine_id,
      ["Jeff", "bossie"], ["proc1", "proc2"],
      date: @in_last_month)
    :ok
  end

  describe "show animal uses" do
    test "success", %{conn: conn} do
      %{assigns: %{uses: [bossie, jeff]}} = 
        post_to_action(conn, :use_last_month, under(:animals, %{}))
      assert %{animal: {"bossie", _id}} = bossie
      assert %{procedures: [%{count: 1}, %{count: 1}]} = bossie
      assert [{"proc1", _id1}, {"proc2", _id2}] = animal_procedures(bossie)

      assert %{animal: {"Jeff", _id}} = jeff
      assert %{procedures: [%{count: 1}, %{count: 1}]} = jeff
      assert [{"proc1", _id1}, {"proc2", _id2}] = animal_procedures(jeff)
    end
  end

  def animal_procedures(animal_entry) do
    Enum.map(animal_entry.procedures, fn procedure_and_count ->
      procedure_and_count.procedure
    end)
  end
end
