defmodule Crit.Exemplars.Minimal do
  use ExUnit.CaseTemplate
  alias Crit.Factory
  alias Crit.Users.{Password, PasswordToken}
  alias Crit.Sql
  use Crit.Institutions.Default

  def user(opts \\ []) do
    user = Factory.sql_insert!(:user, opts, @default_short_name)
    assert Password.count_for(user.auth_id, @default_short_name) == 0
    refute Sql.exists?(PasswordToken, @default_short_name)
    user
  end

  def animal(opts \\ []) do
    Factory.sql_insert!(:animal, opts, @default_short_name)
  end
end
