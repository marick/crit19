defmodule Crit.Sql.PrefixServerTest do
  use Crit.DataCase
  alias Crit.Repo
  alias Crit.Sql
  alias Crit.Audit.ToEcto.Record  # It's one of the simplest table types.
  alias Crit.Global
  alias Crit.Exemplars.Minimal

  @institution Global.Default.institution.short_name
  @prefix Global.Default.institution.prefix

  setup do
    user = Minimal.user
    params = %{event: "event", event_owner_id: user.id, data: %{"a" => 1}}
    [changeset: Record.changeset(%Record{}, params)]
  end

  test "Sql.insert acts like Repo.insert", %{changeset: changeset} do
    assert_same_audit_content(
      Sql.insert!( changeset, @institution),
      Repo.insert!(changeset, prefix: @prefix))
  end

  test "Sql actually modifies the correct Postgres schema", %{changeset: changeset} do
    written = Sql.insert!(changeset, @institution)
    read = Repo.get(Record, written.id, prefix: @prefix)
    assert_same_audit_content(written, read)
  end

  def assert_same_audit_content(one, other),
    do: assert_copy(one, other, except: [:id, :inserted_at])
end
