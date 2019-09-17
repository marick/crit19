defmodule Crit.Factory do
  use ExMachina.Ecto, repo: Crit.Repo
  alias Crit.Users.{User,PermissionList}
  alias Crit.Usables.{Animal}
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
    %Animal{
      name: Faker.Cat.name(),
      species_id: some_species_id()
     }
  end

  def date_pair() do
    import Faker.Date, only: [backward: 1, forward: 1]
    import Date, only: [add: 2]

    kind_of_start = Enum.random(["past", "today", "future"])
    use_never = Enum.random(["never", "some appropriate date"])

    s = &Date.to_iso8601/1

    case {kind_of_start, use_never} do
      {"past", "never"} ->
        { s.(backward(100)), "never"}
      {"past", _} ->
        { s.(backward(100) |> add(-100)), 
          s.(backward(100))
        }

      {"today", "never"} ->
        { "today", "never"}
      {"today", _} ->
        { "today", s.(forward(100)) }

      {"future", "never"} ->
        { s.(forward(100)) , "never" }
      {"future", _} ->
        { s.(forward(100)),
          s.(forward(100) |> add(100))
        }
    end
  end

  # Warning: this depends on the fact that the test database has
  # at least two species.
  Faker.sampler(:some_species_id, [1, 2])
      
  defp some_boolean(), do: Enum.random([true, false])
end
