use Mix.Config


config :spikes, Spikes.Repo,
  database: "spikes_test",
  username: "bem",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
