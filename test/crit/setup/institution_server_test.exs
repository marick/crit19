defmodule Crit.Setup.InstitutionServerTest do
  use Crit.DataCase
  alias Crit.Setup.Schemas.Institution
  alias Ecto.Changeset
  import Crit.Setup.InstitutionServer, only: [server: 1]
  alias Crit.Exemplars.ReservationFocused

  setup do
    [server: server(@institution)]
  end

  test "an institution registers its name", %{server: server} do
    assert_holds_default_institution(server)
  end

  test "an institution is supervised", %{server: server} do
    GenServer.stop(server, :shutdown)
    ref = Process.monitor(server)
    receive do
      {:DOWN, ^ref, _, _, _} ->
        Process.sleep 10    # There is no doubt a better way
        assert_holds_default_institution(server)
    end
  end

  test "institution data can be reloaded", %{server: server} do
    institution = Repo.get_by(Institution, short_name: @institution)
    tweaked = Changeset.change(institution, %{display_name: "Completely new"})
    assert {:ok, _} = Repo.update(tweaked)

    assert :ok = GenServer.call(server, :reload)
    raw = GenServer.call(server, :raw)
    assert raw.display_name == "Completely new"
  end

  test "can find a slot by id", %{server: server} do
    expected = ReservationFocused.some_timeslot
    {:ok, found} = GenServer.call(server, {:timeslot_by_id, expected.id})

    assert_fields(found,
      name: expected.name,
      start: expected.start,
      duration: expected.duration)
  end

  

  defp assert_holds_default_institution(server) do 
    assert %{short_name: @institution} = GenServer.call(server, :raw)
  end

end
