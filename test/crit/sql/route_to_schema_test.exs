defmodule Crit.Sql.RouteToSchemaTest do
  use Crit.DataCase
  alias Crit.Repo
  alias Crit.Sql
  alias Crit.Audit.ToEcto.Record  # It's one of the simplest table types.
  alias Crit.Exemplars.Minimal
  use FlowAssertions

  setup do
    user = Minimal.user
    params = %{event: "event", event_owner_id: user.id, data: %{"a" => 1}}
    [changeset: Record.changeset(%Record{}, params)]
  end

  test "Sql.insert acts like Repo.insert", %{changeset: changeset} do
    assert_same_audit_content(
      Sql.insert!( changeset, @institution),
      Repo.insert!(changeset, prefix: @default_prefix))
  end

  test "Sql actually modifies the correct Postgres schema", %{changeset: changeset} do
    written = Sql.insert!(changeset, @institution)
    read = Repo.get(Record, written.id, prefix: @default_prefix)
    assert_same_audit_content(written, read)
  end

  def assert_same_audit_content(one, other),
    do: assert_same_map(one, other, ignoring: [:id, :inserted_at])
end
