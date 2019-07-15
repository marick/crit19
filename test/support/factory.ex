defmodule Crit.Factory do
  use ExMachina.Ecto, repo: Crit.Repo
  alias Crit.Users.{User,PermissionList,PasswordToken,Password}
  alias Crit.EmailToken

  def user_factory() do
    %User{
      active: true,
      display_name: Faker.Name.name(),
      auth_id: sequence(:auth_id, &"auth-id-#{&1}"),
      email: sequence(:email, &"email-#{&1}@example.com"),
      permission_list: build(:permission_list)
    }
  end

  def permission_list_factory() do
    %PermissionList{
      manage_and_create_users: some_boolean(), 
      manage_animals: some_boolean(), 
      make_reservations: some_boolean(), 
      view_reservations: some_boolean(), 
    }
  end

  def password_token_factory() do
    %PasswordToken{
      text: EmailToken.generate()
    }
  end

  defp some_boolean(), do: Enum.random([true, false])
end
