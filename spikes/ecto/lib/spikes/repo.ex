defmodule Spikes.Repo do
  use Ecto.Repo,
    otp_app: :spikes, 
    adapter: Ecto.Adapters.Postgres
end

  
