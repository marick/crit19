defmodule Spikes.ReservationBundleTest do
  use ExUnit.Case, async: true
  alias Spikes.{Repo, ReservationBundle}
  alias Ecto2.Timespan
  import Spikes.Factory
  import Spikes.Repo

  @timespan_start Faker.NaiveDateTime.backward(20)
  @timespan_past_end  Faker.NaiveDateTime.forward(20)
  @timespan Timespan.customary(@timespan_start, @timespan_past_end)

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Spikes.Repo)
  end

  test "only animals in a bundle are fetched" do
    in_bundle = insert_some!(:animal)
    not_in_bundle = insert_some!(:animal)
    
    bundle = insert_some!(:reservation_bundle,
          animals: [in_bundle],
          relevant_during: @timespan
        )

    actual = ReservationBundle.bundle_animal_ids(bundle.id, @timespan) |> Repo.all
    assert actual == [%{animal_id: in_bundle.id}]
  end

  test "bundles are only visible during their timespan" do
    bundle = insert_some!(:reservation_bundle,
          relevant_during: @timespan
        )

    try = fn(timespan) -> ReservationBundle.bundles(timespan) |> Repo.all end

    assert try.(hour_starting_at(@timespan_start)) == [bundle]

    # One outside the range is not selected
    assert try.(hour_starting_at(@timespan_past_end)) == []


    # An overlapping range is also not selected
    early_start = NaiveDateTime.add(@timespan_start, -1, :second)
    assert try.(hour_starting_at(early_start)) == []
  end


  defp hour_starting_at(from) do
    Timespan.plus(from, 60, :minute)
  end

  defp insert_some!(thing, params \\ []) do
    insert!(build(thing, params))
  end
  
    
end
