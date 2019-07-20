defmodule Crit.HistoryTest do
  use Crit.DataCase
  alias Crit.Repo

  alias Crit.History
  alias Crit.History.Audit

  @user_id 55

  test "audit logging" do
    data = %{string: "some data", int: 5}
    assert %Audit{} = History.record("some_event", @user_id, data)

    [one] = Repo.all(Audit)

    assert one.event == "some_event"
    assert one.event_owner == @user_id
    assert one.data["string"] == "some data"
    assert one.data["int"] == 5
  end

  describe "selecting the most recent audit record" do
    test "nothing there" do
      assert History.no_audit_match == History.single_most_recent("some_event")
    end

    test "something there, but not of the desired event" do
      desired = "some event"
      actual = "some other event"
      History.record(actual, @user_id, %{})
      assert History.no_audit_match == History.single_most_recent(desired)
    end

    test "something there, of the desired event" do
      event = "some event"
      original = History.record(event, @user_id, %{})
      {:ok, actual} = History.single_most_recent(event)
      assert_audit_record(original, actual)
    end

    test "gets the most recent" do
      event = "some event"
      earlier = History.record(event, @user_id, %{})
      age(Audit, earlier.id, 10)
      later = History.record(event, @user_id, %{})

      {:ok, fetched} = History.single_most_recent(event)
      assert_audit_record(later, fetched)
    end
  end

  describe "selecting the N most recent audit records" do
    test "nothing there" do
      assert [] == History.n_most_recent(3, "some event")
    end

    test "in ascending order" do 
      desired = "some event"
      undesired = "some other event"

      earlier = History.record(desired, @user_id, %{tag: "earlier"})
      age(Audit, earlier.id, 10)

      History.record(undesired, @user_id, %{tag: "undesired"})

      later = History.record(desired, @user_id, %{tag: "later"})

      assert [top, lower] = History.n_most_recent(2, desired)

      assert_audit_record(later, top)
      assert_audit_record(earlier, lower)
    end

    test "has a limit" do
      History.record("event", @user_id, %{})
      History.record("event", @user_id, %{})
      History.record("event", @user_id, %{})

      assert [fetched1, fetched2] = History.n_most_recent(2, "event")
    end
  end

  def assert_audit_record(desired, actual), do: assert desired.id == actual.id
end
