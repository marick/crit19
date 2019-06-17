use Mix.Config


config :spikes, Spikes.Repo,
  database: "spikes",
  username: "bem",
  password: "postgres",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
