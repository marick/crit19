defmodule Crit.Repo do
  use Ecto.Repo,
    otp_app: :crit,
    adapter: Ecto.Adapters.Postgres
end
