defmodule Crit.HistoryTest do
  use Crit.DataCase
  alias Crit.Repo

  alias Crit.History
  alias Crit.History.Audit
  alias Crit.History.AuditEvents

  @user_id 55

  test "audit logging" do
    data = %{string: "some data", int: 5}
    assert %Audit{} = History.record(:login, @user_id, data)

    [one] = Repo.all(Audit)

    assert one.event == AuditEvents.to_string(:login)
    assert one.event_owner_id == @user_id
    assert one.data["string"] == "some data"
    assert one.data["int"] == 5
  end

  describe "selecting the most recent audit record" do
    test "nothing there" do
      assert History.no_audit_match == History.last_audit(:login)
    end

    test "something there, but not of the desired event" do
      desired = :login
      actual = :created_user
      History.record(actual, @user_id, %{})
      assert History.no_audit_match == History.last_audit(desired)
    end

    test "something there, of the desired event" do
      original = History.record(:login, @user_id, %{})
      {:ok, actual} = History.last_audit(:login)
      assert_audit_record(original, actual)
    end

    test "gets the most recent" do
      earlier = History.record(:login, @user_id, %{})
      age(Audit, earlier.id, 10)
      later = History.record(:login, @user_id, %{})

      {:ok, fetched} = History.last_audit(:login)
      assert_audit_record(later, fetched)
    end
  end

  describe "selecting the N most recent audit records" do
    test "nothing there" do
      assert [] == History.last_n_audits(3, :login)
    end

    test "in ascending order" do 
      desired = :login
      undesired = :created_user

      earlier = History.record(desired, @user_id, %{tag: "earlier"})
      age(Audit, earlier.id, 10)

      History.record(undesired, @user_id, %{tag: "undesired"})

      later = History.record(desired, @user_id, %{tag: "later"})

      assert [top, lower] = History.last_n_audits(2, desired)

      assert_audit_record(later, top)
      assert_audit_record(earlier, lower)
    end

    test "has a limit" do
      History.record(:login, @user_id, %{})
      History.record(:login, @user_id, %{})
      History.record(:login, @user_id, %{})

      assert [fetched1, fetched2] = History.last_n_audits(2, :login)
    end
  end

  def assert_audit_record(desired, actual), do: assert desired.id == actual.id

end
