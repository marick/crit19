defmodule Crit.Factory do
  use ExMachina.Ecto, repo: Crit.Repo
  alias Crit.Accounts.{User}
  alias Faker.{Name,String}

  def user_factory() do
    %User{
      active: true,
      email: sequence(:email, &"email-#{&1}@example.com"),
      name: Name.name(),
      password: String.base64(32),
    }
  end
end
