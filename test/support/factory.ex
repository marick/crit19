defmodule Crit.Factory do
  use ExMachina.Ecto, repo: Crit.Repo
  alias Crit.Users.{User,PermissionList}
  alias Crit.Usables.Write
  #  alias Ecto.Datespan
  alias Crit.Sql
  require Faker

  def sql_insert!(tag, opts \\ [], institution) do
    build(tag, opts) |> Sql.insert!(institution)
  end

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

  def animal_factory() do
    %Write.Animal{
      name: Faker.Cat.name(),
      species_id: some_species_id()
     }
  end


  def unique_names_string() do
    unique_names() |> names_to_input_string()
  end

  def names_to_input_string(names), do: Enum.join(names, ", ")

  def unique_names() do 
    Faker.Cat.name()
    |> List.duplicate(Faker.random_between(1, 20))
    |> Enum.with_index
    |> Enum.map(fn {name, index} -> "#{name}_!_#{index}" end)
  end



  # Warning: this depends on the fact that the test database has
  # at least two species.
  Faker.sampler(:some_species_id, [1, 2])
      
  defp some_boolean(), do: Enum.random([true, false])
end
