defmodule Crit.Schemas.Institution.ServerTest do
  use Crit.DataCase
  alias Crit.Schemas.Institution
  alias Crit.Servers.Institution.Server
  alias Ecto.Changeset

  setup do
    [server: Server.server(@institution)]
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
    raw = GenServer.call(server, {:get, :institution})
    assert raw.display_name == "Completely new"
  end


  defp assert_holds_default_institution(server) do 
    assert %{short_name: @institution} = GenServer.call(server, {:get, :institution})
  end

end
