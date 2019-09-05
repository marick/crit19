defmodule Crit.Ecto.DateSpanTest do
  use Crit.DataCase
  # alias Ecto.Timespan
  # import Ecto.Timespan
  # alias Crit.Usables.{ScheduledUnavailability}
  # alias Crit.Exemplars.Minimal
  # alias Crit.Sql


  # defp animal_with(timespan) do
  #   unavailability = %ScheduledUnavailability{
  #     timespan: timespan,
  #     reason: "foo"
  #   }
      
  #   Minimal.animal(scheduled_unavailabilities: [unavailability])
  # end

  # @moment      ~N[2000-01-01 01:02:03]
  # @prev_moment ~N[2000-01-01 01:02:02]
  # @next_moment ~N[2000-01-01 01:02:04]
  # @long_ago    ~N[1990-01-01 01:02:04]
  # @far_forward ~N[2990-01-01 01:02:04]

  # defp db_contains?(timespan) do
  #   {:ok, range} = timespan |> Timespan.dump
  #   query = from s in ScheduledUnavailability, where: contains(s.timespan, ^range)
  #   Sql.exists?(query, @default_short_name)
  # end
  
  # defp db_overlaps?(timespan) do
  #   {:ok, range} = timespan |> Timespan.dump
  #   query = from s in ScheduledUnavailability, where: overlaps(s.timespan, ^range)
  #   Sql.exists?(query, @default_short_name)
  # end
  
  # test "infinite down && containment" do
  #   database_span = Timespan.infinite_down(@moment, :exclusive)
  #   animal_with(database_span)
    
  #   assert db_contains?(Timespan.infinite_down(@moment, :exclusive))
  #   assert db_contains?(Timespan.infinite_down(@prev_moment, :exclusive))
  #   refute db_contains?(Timespan.infinite_down(@next_moment, :exclusive))

  #   refute db_contains?(Timespan.infinite_down(@moment, :inclusive))
  #   assert db_contains?(Timespan.infinite_down(@prev_moment, :inclusive))
  #   refute db_contains?(Timespan.infinite_down(@next_moment, :inclusive))

  #   assert db_contains?(Timespan.customary(@long_ago, @prev_moment))
  #   assert db_contains?(Timespan.customary(@long_ago, @moment))
  #   refute db_contains?(Timespan.customary(@long_ago, @next_moment))

  #   refute db_contains?(Timespan.infinite_up(@long_ago, :inclusive))
  #   refute db_contains?(Timespan.infinite_up(@long_ago, :exclusive))

  #   refute db_contains?(Timespan.for_instant(@moment))
  #   assert db_contains?(Timespan.for_instant(@prev_moment))
  # end

  # test "infinite down && overlap" do
  #   database_span = Timespan.infinite_down(@moment, :exclusive)
  #   animal_with(database_span)

  #   refute db_overlaps?(Timespan.for_instant(@moment))
  #   assert db_overlaps?(Timespan.for_instant(@prev_moment))

  #   refute db_overlaps?(Timespan.customary(@moment, @far_forward))
  #   assert db_overlaps?(Timespan.customary(@prev_moment, @far_forward))

  #   refute db_overlaps?(Timespan.infinite_up(@moment, :inclusive))
  #   assert db_overlaps?(Timespan.infinite_up(@prev_moment, :inclusive))
  #   # There is < 1 second of overlap
  #   assert db_overlaps?(Timespan.infinite_up(@prev_moment, :exclusive))

  #   assert db_overlaps?(Timespan.infinite_down(@moment, :inclusive))
  #   assert db_overlaps?(Timespan.infinite_down(@prev_moment, :inclusive))
  #   assert db_overlaps?(Timespan.infinite_down(@next_moment, :inclusive))
    
  #   assert db_overlaps?(Timespan.infinite_down(@moment, :exclusive))
  #   assert db_overlaps?(Timespan.infinite_down(@prev_moment, :exclusive))
  #   assert db_overlaps?(Timespan.infinite_down(@next_moment, :exclusive))
  # end

  # test "infinite up and containment" do
  #   database_span = Timespan.infinite_up(@moment, :exclusive)
  #   animal_with(database_span)

  #   assert db_contains?(Timespan.infinite_up(@moment, :exclusive))
  #   refute db_contains?(Timespan.infinite_up(@prev_moment, :exclusive))
  #   assert db_contains?(Timespan.infinite_up(@next_moment, :exclusive))
    
  #   refute db_contains?(Timespan.infinite_up(@moment, :inclusive))
  #   refute db_contains?(Timespan.infinite_up(@prev_moment, :inclusive))
  #   assert db_contains?(Timespan.infinite_up(@next_moment, :inclusive))

  #   refute db_contains?(Timespan.infinite_down(@far_forward, :inclusive))

  #   refute db_contains?(Timespan.for_instant(@moment))
  #   refute db_contains?(Timespan.for_instant(@prev_moment))
  #   assert db_contains?(Timespan.for_instant(@next_moment))

  #   refute db_contains?(Timespan.customary(@moment, @next_moment))
  #   assert db_contains?(Timespan.customary(@next_moment, @far_forward))
  # end
  
  # test "infinite up and overlap" do
  #   database_span = Timespan.infinite_up(@moment, :exclusive)
  #   animal_with(database_span)

  #   refute db_overlaps?(Timespan.infinite_down(@moment, :inclusive))
  #   assert db_overlaps?(Timespan.infinite_down(@next_moment, :inclusive))
  #   assert db_overlaps?(Timespan.infinite_down(@next_moment, :exclusive))

  #   refute db_overlaps?(Timespan.for_instant(@moment))
  #   assert db_overlaps?(Timespan.for_instant(@next_moment))

  #   assert db_overlaps?(Timespan.customary(@moment, @next_moment))
  #   refute db_overlaps?(Timespan.customary(@prev_moment, @moment))
  # end

  # test "inclusive infinite up" do
  #   database_span = Timespan.infinite_up(@moment, :inclusive)
  #   animal_with(database_span)

  #   assert db_contains?(Timespan.infinite_up(@moment, :exclusive))
  #   assert db_contains?(Timespan.for_instant(@moment))

  #   assert db_contains?(Timespan.customary(@moment, @next_moment))


  #   refute db_overlaps?(Timespan.customary(@long_ago, @moment))
  #   assert db_overlaps?(Timespan.customary(@long_ago, @next_moment))

  #   assert db_overlaps?(Timespan.for_instant(@moment))
  # end

  # test "customary" do
  #   database_span = Timespan.customary(@moment, @next_moment)
  #   animal_with(database_span)

  #   assert db_contains?(Timespan.customary(@moment, @next_moment))
  #   assert db_overlaps?(Timespan.customary(@moment, @next_moment))
    
  #   refute db_contains?(Timespan.customary(@moment, @far_forward))
  #   assert db_overlaps?(Timespan.customary(@moment, @far_forward))
    
  #   refute db_contains?(Timespan.customary(@prev_moment, @moment))
  #   refute db_overlaps?(Timespan.customary(@prev_moment, @moment))

  #   assert db_contains?(Timespan.for_instant(@moment))
  #   assert db_overlaps?(Timespan.for_instant(@moment))

  #   refute db_contains?(Timespan.for_instant(@next_moment))
  #   refute db_overlaps?(Timespan.for_instant(@next_moment))

  #   refute db_contains?(Timespan.infinite_down(@far_forward, :inclusive))
  #   assert db_overlaps?(Timespan.infinite_down(@far_forward, :inclusive))
  #   refute db_overlaps?(Timespan.infinite_down(@moment, :exclusive))
  #   assert db_overlaps?(Timespan.infinite_down(@moment, :inclusive))

  #   refute db_overlaps?(Timespan.infinite_up(@next_moment, :inclusive))
  # end

  # test "for_instant" do
  #   database_span = Timespan.for_instant(@moment)
  #   animal_with(database_span)

  #   assert db_contains?(database_span)
  #   refute db_contains?(Timespan.for_instant(@prev_moment))
  #   refute db_contains?(Timespan.for_instant(@next_moment))

  #   assert db_overlaps?(database_span)
  #   refute db_overlaps?(Timespan.for_instant(@prev_moment))
  #   refute db_overlaps?(Timespan.for_instant(@next_moment))

  #   assert db_overlaps?(Timespan.customary(@moment, @next_moment))
  #   refute db_overlaps?(Timespan.customary(@next_moment, @far_forward))
  # end

  # test "plus" do
  #   plus_form = Timespan.plus(          ~N[2001-01-01 01:02:03], 10, :minute)
  #   customary_form = Timespan.customary(~N[2001-01-01 01:02:03],
  #                                       ~N[2001-01-01 01:12:03])
  #   assert plus_form == customary_form
  # end
  
end
