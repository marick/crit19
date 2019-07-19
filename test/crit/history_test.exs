defmodule Crit.HistoryTest do
  use Crit.DataCase
  alias Crit.Repo

  alias Crit.History
  alias Crit.History.Audit

  test "audit logging" do
    data = %{string: "some data", int: 5}
    History.record("some_event", 55, data)

    [one] = Repo.all(Audit)

    assert one.event == "some_event"
    assert one.event_owner == 55
    assert one.data["string"] == "some data"
    assert one.data["int"] == 5
                    
  end
end
