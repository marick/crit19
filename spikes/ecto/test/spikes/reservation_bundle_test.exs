defmodule Spikes.ReservationBundleTest do
  use ExUnit.Case, async: true
  alias Spikes.{Repo}
  alias Ecto2.Timespan
  import Spikes.Factory
  import Spikes.Repo

  @timespan_start Faker.NaiveDateTime.backward(20)
  @timespan_past_end  Faker.NaiveDateTime.forward(20)
  @timespan Timespan.customary(@timespan_start, @timespan_past_end)

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Spikes.Repo)
  end

  describe "queries" do
    alias Spikes.ReservationBundle.Query


    test "only animals in a bundle are fetched" do
      in_bundle = insert_some!(:animal)
      _not_in_bundle = insert_some!(:animal)
      
      bundle = insert_some!(:reservation_bundle,
        animals: [in_bundle]
      )
      
      actual = Query.bundle_animal_ids(bundle.id) |> Repo.all
      assert actual == [%{animal_id: in_bundle.id}]
    end
    
    test "bundles are only visible during their timespan" do
      bundle = insert_some!(:reservation_bundle,
        relevant_during: @timespan
      )
      
      try = fn(timespan) -> Query.bundles(timespan) |> Repo.all end
      
      assert try.(hour_starting_at(@timespan_start)) == [bundle]
      
      # One outside the range is not selected
      assert try.(hour_starting_at(@timespan_past_end)) == []
      
      
      # An overlapping range is also not selected
      early_start = NaiveDateTime.add(@timespan_start, -1, :second)
      assert try.(hour_starting_at(early_start)) == []
    end
  end

  describe "io" do
    alias Spikes.ReservationBundle.Db

    test "fetching values to display in a name list" do 
      desired_timespan = @timespan
      omitted_timespan = hour_starting_at(@timespan_past_end)
    
      desired = insert_some!(:reservation_bundle, relevant_during: desired_timespan)
      _omitted = insert_some!(:reservation_bundle, relevant_during: omitted_timespan)

      [actual] = Db.bundles_for_list(desired_timespan)
      assert actual.id == desired.id
      assert actual.name == desired.name
      assert true == unloaded?(desired.animals)
      assert true == unloaded?(desired.procedures)
    end
  end

  defp unloaded?(%Ecto.Association.NotLoaded{}), do: true
  defp unloaded?(_), do: false
  

  defp hour_starting_at(from) do
    Timespan.plus(from, 60, :minute)
  end

  defp insert_some!(thing, params \\ []) do
    insert!(build(thing, params))
  end
end
