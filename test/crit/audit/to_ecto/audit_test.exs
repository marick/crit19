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

  test "audit logging" do
    id = 3
    event = "event"
    data = %{s: "string", i: 44}

    Server.put(
      :ignored,
      %Entry{event_owner_id: id, event: event, data: data},
      @default_institution
    )
    wait_for_cast_to_complete()
    assert [one] = Sql.all(Record, @default_institution)

    assert one.event_owner_id == id
    assert one.event == event
    # Note stringification of keys
    assert one.data == %{"i" => 44, "s" => "string"}
  end

  defp wait_for_cast_to_complete, do: :sys.get_state(Server)
end
