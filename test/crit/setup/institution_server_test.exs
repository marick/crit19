defmodule Crit.Setup.InstitutionServerTest do
  use Crit.DataCase
  alias Crit.Setup.Schemas.Institution
  alias Ecto.Changeset

  setup do
    [pid: String.to_atom(@institution)]
  end

  test "an institution registers its name", %{pid: pid} do
    assert_holds_default_institution(pid)
  end

  test "an institution is supervised", %{pid: pid} do
    GenServer.stop(pid, :shutdown)
    ref = Process.monitor(pid)
    receive do
      {:DOWN, ^ref, _, _, _} ->
        Process.sleep 10    # There is no doubt a better way
        assert_holds_default_institution(pid)
    end
  end

  test "institution data can be reloaded", %{pid: pid} do
    institution = Repo.get_by(Institution, short_name: @institution)
    tweaked = Changeset.change(institution, %{display_name: "Completely new"})
    assert {:ok, _} = Repo.update(tweaked)

    assert :ok = GenServer.call(pid, :reload)
    raw = GenServer.call(pid, :raw)
    assert raw.display_name == "Completely new"
  end

  defp assert_holds_default_institution(pid) do 
    assert %{short_name: @institution} = GenServer.call(pid, :raw)
  end
end
