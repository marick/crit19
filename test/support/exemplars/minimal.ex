defmodule Crit.Exemplars.Minimal do
  @moduledoc """
  This is for dirt-simple structures where only a few most obvious structure
  fields are relevant. Typically, for example, associated records are not
  created.
  """ 
  
  use ExUnit.CaseTemplate
  use Crit.Global.Default
  use Crit.Global.Constants
  alias Crit.Factory
  alias Crit.Users.{Password, PasswordToken}
  alias Crit.Usables.Schemas.ServiceGap
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

  def service_gap(id) when is_integer(id), do: %ServiceGap{id: id}
end
