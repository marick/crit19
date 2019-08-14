defmodule Crit.Sql.PrefixServerTest do
  use Crit.DataCase
  alias Crit.Repo
  alias Crit.Sql
  alias Crit.Audit.ToEcto.Record  # It's one of the simplest table types.
  alias Crit.Institutions
  alias Crit.Exemplars.Minimal

  @institution Institutions.Default.institution.short_name
  @prefix Institutions.Default.institution.prefix

  test "use of the server" do
    user = Minimal.user()
    assert {:ok, direct} = Repo.insert(record_for(user), prefix: @prefix)
    assert {:ok, indirect} = Sql.insert(record_for(user), @institution)

    assert_inserted_the_same(direct, indirect)
    assert_in_correct_postgres_schema(indirect)
  end

  def record_for(user) do 
    params = %{event: "event", event_owner_id: user.id, data: %{"a" => 1}}
    Record.changeset(%Record{}, params)
  end

  def assert_inserted_the_same(one, other) do
    assert one.event == other.event
    assert one.event_owner_id == other.event_owner_id
    assert one.data == other.data
  end

  def assert_in_correct_postgres_schema(inserted) do
    fetched = Repo.get(Record, inserted.id, prefix: @prefix)
    assert_inserted_the_same(inserted, fetched)
  end
end
