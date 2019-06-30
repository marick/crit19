defmodule Crit.Factory do
  use ExMachina.Ecto, repo: Crit.Repo
  alias Crit.Accounts.{User}
  alias Faker.{Name,String}

  def user_factory() do
    %User{
      active: true,
      display_name: Name.name(),
      auth_id: sequence(:auth_id, &"visible-id-#{&1}"),
      email: sequence(:email, &"email-#{&1}@example.com"),
      password: String.base64(32),
      password_hash: "THIS SHOULD BE OVERWRITTEN"
    }
  end
end
