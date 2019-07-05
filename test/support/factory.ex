defmodule Crit.Factory do
  use ExMachina.Ecto, repo: Crit.Repo
  alias Faker.{Name,String}
  alias Crit.Users.User

  def user_factory() do
    %User{
      active: true,
      display_name: Name.name(),
      auth_id: sequence(:auth_id, &"auth-id-#{&1}"),
      email: sequence(:email, &"email-#{&1}@example.com"),
    }
  end
end
