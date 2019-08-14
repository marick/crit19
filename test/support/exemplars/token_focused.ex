defmodule Crit.Exemplars.TokenFocused do
  use ExUnit.CaseTemplate
  alias Crit.Users
  alias Crit.Factory
  use Crit.Institutions.Default
  alias Crit.Users.UserHavingToken, as: UT


  def possible_user(attrs \\ []) do
    params = Factory.string_params_for(:user, attrs)
    Users.create_unactivated_user(params, @default_short_name)
  end

  def user(attrs \\ []) do
    {:ok, %UT{} = tokenized} = possible_user(attrs)
    tokenized
  end

end
