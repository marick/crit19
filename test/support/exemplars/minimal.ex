defmodule Crit.Exemplars.Minimal do
  @moduledoc """
  This is for dirt-simple structures where only a few most obvious structure
  fields are relevant. Typically, for example, associated records are not
  created.
  """ 
  
  use ExUnit.CaseTemplate
  use Crit.Global.Constants
  alias Crit.Factory
  alias Crit.Users.Schemas.{Password, PasswordToken}
  alias Crit.Sql

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
