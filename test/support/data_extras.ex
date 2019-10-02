defmodule Crit.DataExtras do
  import ExUnit.Assertions
  alias Crit.Users.{PermissionList, UniqueId}
  use Crit.Global.Default
  alias Ecto.Datespan


  def assert_without_permissions(user) do
    refute %PermissionList{} == user.permission_list
  end

  def assert_ok_unique_id(required_user_id,
                          {:ok, %UniqueId{} = actual}) do
    required_id = UniqueId.new(required_user_id, @institution)
    assert required_id == actual
  end


  # Datespans contain Dates, so strictly shouldn't be compared with
  # equality. However, in this case, we're really asserting that
  # the two dates were produced by a function call with the same
  # arguments. Given pure functions, that's safe.
  def assert_same_date(%Datespan{} = span, %Datespan{} = expected),
    do: assert span == expected


  def assert_strictly_before(%Datespan{} = span, %Date{} = date),
    do: assert_same_date(span, Datespan.strictly_before(date))

  def assert_date_and_after(%Datespan{} = span, %Date{} = date),
    do: assert_same_date(span, Datespan.date_and_after(date))
  
end
