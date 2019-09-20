defmodule Crit.Exemplars.Minimal do
  use ExUnit.CaseTemplate
  alias Crit.Factory
  alias Crit.Users.{Password, PasswordToken}
  alias Crit.Sql
  use Crit.Institutions.Default

  def user(opts \\ []) do
    user = Factory.sql_insert!(:user, opts, @institution)
    assert Password.count_for(user.auth_id, @institution) == 0
    refute Sql.exists?(PasswordToken, @institution)
    user
  end

  def animal(opts \\ []) do
    Factory.sql_insert!(:animal, opts, @institution)
  end
end
