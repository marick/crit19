ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Crit.Repo, :manual)
Faker.start()


Mox.defmock(Crit.Sql.Mock, for: Crit.Sql.Api)
