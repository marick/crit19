defmodule Crit.Ecto.TimespanTest do

  # These tests have two reasons:
  # 1. old tests that serve as sanity tests. Keep changes to Span up to date
  # by using DatespanTest.
  # 2. test functions special to timespans. These come first in the file.
  
  use Crit.DataCase
  alias Ecto.Timespan
  import Ecto.Timespan
  alias Crit.Usables.Write
  alias Crit.Sql
  alias Pile.TimeHelper

  @moment      ~N[2000-01-01 01:02:03]
  @prev_moment ~N[2000-01-01 01:02:02]
  @next_moment ~N[2000-01-01 01:02:04]
  @long_ago    ~N[1990-01-01 01:02:04]
  @far_forward ~N[2990-01-01 01:02:04]

  test "plus" do
    plus_form = Timespan.plus(          ~N[2001-01-01 01:02:03], 10, :minute)
    customary_form = Timespan.customary(~N[2001-01-01 01:02:03],
                                        ~N[2001-01-01 01:12:03])
    assert plus_form == customary_form
  end


  test "conversions" do
    actual =
      Timespan.from_date_time_and_duration(~D[2019-11-12], ~T[08:00:00], 90)
    # We match the microsecond precision that Postgres gives us.
    expected_start = ~N[2019-11-12 08:00:00] |> TimeHelper.millisecond_precision
    expected_end =   ~N[2019-11-12 09:30:00] |> TimeHelper.millisecond_precision
    assert actual == Timespan.customary(expected_start, expected_end)
  end
  
  

  test "infinite down && containment" do
    database_span = Timespan.infinite_down(@moment, :exclusive)
    add_reservation!(database_span)
    
    assert db_contains?(Timespan.infinite_down(@moment, :exclusive))
    assert db_contains?(Timespan.infinite_down(@prev_moment, :exclusive))
    refute db_contains?(Timespan.infinite_down(@next_moment, :exclusive))

    refute db_contains?(Timespan.infinite_down(@moment, :inclusive))
    assert db_contains?(Timespan.infinite_down(@prev_moment, :inclusive))
    refute db_contains?(Timespan.infinite_down(@next_moment, :inclusive))

    assert db_contains?(Timespan.customary(@long_ago, @prev_moment))
    assert db_contains?(Timespan.customary(@long_ago, @moment))
    refute db_contains?(Timespan.customary(@long_ago, @next_moment))

    refute db_contains?(Timespan.infinite_up(@long_ago, :inclusive))
    refute db_contains?(Timespan.infinite_up(@long_ago, :exclusive))
  end

  test "infinite down && overlap" do
    database_span = Timespan.infinite_down(@moment, :exclusive)
    add_reservation!(database_span)

    refute db_overlaps?(Timespan.customary(@moment, @far_forward))
    assert db_overlaps?(Timespan.customary(@prev_moment, @far_forward))

    refute db_overlaps?(Timespan.infinite_up(@moment, :inclusive))
    assert db_overlaps?(Timespan.infinite_up(@prev_moment, :inclusive))
    # There is < 1 second of overlap
    assert db_overlaps?(Timespan.infinite_up(@prev_moment, :exclusive))

    assert db_overlaps?(Timespan.infinite_down(@moment, :inclusive))
    assert db_overlaps?(Timespan.infinite_down(@prev_moment, :inclusive))
    assert db_overlaps?(Timespan.infinite_down(@next_moment, :inclusive))
    
    assert db_overlaps?(Timespan.infinite_down(@moment, :exclusive))
    assert db_overlaps?(Timespan.infinite_down(@prev_moment, :exclusive))
    assert db_overlaps?(Timespan.infinite_down(@next_moment, :exclusive))
  end

  test "infinite up and containment" do
    database_span = Timespan.infinite_up(@moment, :exclusive)
    add_reservation!(database_span)

    assert db_contains?(Timespan.infinite_up(@moment, :exclusive))
    refute db_contains?(Timespan.infinite_up(@prev_moment, :exclusive))
    assert db_contains?(Timespan.infinite_up(@next_moment, :exclusive))
    
    refute db_contains?(Timespan.infinite_up(@moment, :inclusive))
    refute db_contains?(Timespan.infinite_up(@prev_moment, :inclusive))
    assert db_contains?(Timespan.infinite_up(@next_moment, :inclusive))

    refute db_contains?(Timespan.infinite_down(@far_forward, :inclusive))

    refute db_contains?(Timespan.customary(@moment, @next_moment))
    assert db_contains?(Timespan.customary(@next_moment, @far_forward))
  end
  
  test "infinite up and overlap" do
    database_span = Timespan.infinite_up(@moment, :exclusive)
    add_reservation!(database_span)

    refute db_overlaps?(Timespan.infinite_down(@moment, :inclusive))
    assert db_overlaps?(Timespan.infinite_down(@next_moment, :inclusive))
    assert db_overlaps?(Timespan.infinite_down(@next_moment, :exclusive))

    assert db_overlaps?(Timespan.customary(@moment, @next_moment))
    refute db_overlaps?(Timespan.customary(@prev_moment, @moment))
  end

  test "inclusive infinite up" do
    database_span = Timespan.infinite_up(@moment, :inclusive)
    add_reservation!(database_span)

    assert db_contains?(Timespan.infinite_up(@moment, :exclusive))

    assert db_contains?(Timespan.customary(@moment, @next_moment))


    refute db_overlaps?(Timespan.customary(@long_ago, @moment))
    assert db_overlaps?(Timespan.customary(@long_ago, @next_moment))

  end

  test "customary" do
    database_span = Timespan.customary(@moment, @next_moment)
    add_reservation!(database_span)

    assert db_contains?(Timespan.customary(@moment, @next_moment))
    assert db_overlaps?(Timespan.customary(@moment, @next_moment))
    
    refute db_contains?(Timespan.customary(@moment, @far_forward))
    assert db_overlaps?(Timespan.customary(@moment, @far_forward))
    
    refute db_contains?(Timespan.customary(@prev_moment, @moment))
    refute db_overlaps?(Timespan.customary(@prev_moment, @moment))

    refute db_contains?(Timespan.infinite_down(@far_forward, :inclusive))
    assert db_overlaps?(Timespan.infinite_down(@far_forward, :inclusive))
    refute db_overlaps?(Timespan.infinite_down(@moment, :exclusive))
    assert db_overlaps?(Timespan.infinite_down(@moment, :inclusive))

    refute db_overlaps?(Timespan.infinite_up(@next_moment, :inclusive))
  end

  defp db_contains?(timespan) do
    {:ok, range} = timespan |> Timespan.dump
    query = from s in Write.Reservation, where: contains(s.timespan, ^range)
    Sql.exists?(query, @institution)
  end
  
  defp db_overlaps?(timespan) do
    {:ok, range} = timespan |> Timespan.dump
    query = from s in Write.Reservation, where: overlaps(s.timespan, ^range)
    Sql.exists?(query, @institution)
  end
  
  defp add_reservation!(timespan) do
    reservation = %Write.Reservation{species_id: @bovine_id, timespan: timespan}
    Sql.insert!(reservation, @institution)
  end
end
