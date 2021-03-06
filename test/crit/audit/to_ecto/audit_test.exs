defmodule Crit.Audit.ToEcto.AuditTest do

  # Note: this fails with a `DBConnection.OwnershipError` if `async:
  # true` is set on the next line. Rather than messing around to have
  # this process share its connection with the GenServer process, I'll
  # just run it synchronously.
  use Crit.DataCase
  alias Crit.Audit.CreationStruct, as: Entry
  alias Crit.Audit.ToEcto.Server
  alias Crit.Audit.ToEcto.Record
  alias Crit.Sql
  alias Crit.Exemplars.Minimal

  test "audit logging" do
    user = Minimal.user()
    event = "event"
    data = %{s: "string", i: 44}

    Server.put(
      :ignored,
      %Entry{event_owner_id: user.id, event: event, data: data},
      @institution
    )
    wait_for_cast_to_complete()
    assert [one] = Sql.all(Record, @institution)

    assert one.event_owner_id == user.id
    assert one.event == event
    # Note stringification of keys
    assert one.data == %{"i" => 44, "s" => "string"}
  end

  defp wait_for_cast_to_complete, do: :sys.get_state(Server)
end
