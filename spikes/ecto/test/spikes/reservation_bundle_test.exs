defmodule Spikes.ReservationBundleTest do
  use ExUnit.Case, async: true
  alias Spikes.{Repo, ReservationBundle}
  import Spikes.Factory
  import Spikes.Repo

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Spikes.Repo)
  end

  test "insert" do
    bundle = insert!(build(:reservation_bundle,
          animals: [build(:animal)],
        ))
    IO.inspect(bundle)
  end
end
