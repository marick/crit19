defmodule Crit.Ecto.SpanTest do

  # Testing of functions that work for both types of spans, using
  # Reservation as concrete database table.
  
  use Crit.DataCase
  alias Ecto.{Timespan,Datespan}
  import Ecto.Timespan  # This has to be imported for query construction.
  alias Crit.Usables.Schema.Reservation
  alias Crit.Sql

  @moment      ~N[2000-01-01 01:02:03]
  @prev_moment ~N[2000-01-01 01:02:02]
  @next_moment ~N[2000-01-01 01:02:04]
  @long_ago    ~N[1990-01-01 01:02:04]
  @far_forward ~N[2990-01-01 01:02:04]

  test "equality" do
    # I don't know why equal? sometimes gets passed nils.
    refute Datespan.equal?(
      nil,
      Datespan.customary(~D[2001-01-01], ~D[2002-01-01]))

    refute Datespan.equal?(
      nil,
      Datespan.customary(~D[2001-01-01], ~D[2002-01-01]))

    assert Datespan.equal?(
      Datespan.customary(~D[2001-01-01], ~D[2002-01-01]),
      Datespan.customary(~D[2001-01-01], ~D[2002-01-01]))

    refute Datespan.equal?(
      Datespan.customary(~D[2001-01-01], ~D[2222-12-22]),
      Datespan.customary(~D[2001-01-01], ~D[2002-01-01]))

    refute Datespan.equal?(
      Datespan.customary(~D[2111-11-11], ~D[2002-01-01]),
      Datespan.customary(~D[2001-01-01], ~D[2002-01-01]))

    refute Datespan.equal?(
      Datespan.customary(~D[2001-01-01], ~D[2002-01-01]),
      Datespan.infinite_up(~D[2001-01-01], :inclusive))

    # Not strictly necessary - confirmation test
    refute Datespan.equal?(
      Datespan.customary(~D[2001-01-01], ~D[2002-01-01]),
      Datespan.infinite_up(~D[2001-01-01], :exclusive))

    refute Datespan.equal?(
      Datespan.infinite_down(~D[2001-01-01], :inclusive),
      Datespan.customary(~D[1999-01-01], ~D[2001-01-01]))

    # Not strictly necessary - confirmation test
    refute Datespan.equal?(
      Datespan.infinite_down(~D[2001-01-01], :exclusive),
      Datespan.customary(~D[1999-01-01], ~D[2001-01-01]))

    assert Datespan.equal?(
      Datespan.infinite_down(~D[2001-01-01], :exclusive),
      Datespan.infinite_down(~D[2001-01-01], :exclusive))

    # Not strictly necessary - confirmation test
    assert Datespan.equal?(
      Datespan.infinite_down(~D[2001-01-01], :inclusive),
      Datespan.infinite_down(~D[2001-01-01], :inclusive))

    refute Datespan.equal?(
      Datespan.infinite_down(~D[2001-01-01], :exclusive),
      Datespan.infinite_down(~D[2001-01-01], :inclusive))

    # Not strictly necessary - confirmation test
    refute Datespan.equal?(
      Datespan.infinite_down(~D[2111-11-11], :inclusive),
      Datespan.infinite_down(~D[2001-01-01], :inclusive))

    # Not strictly necessary - confirmation test
    assert Datespan.equal?(
      Datespan.infinite_up(~D[2001-01-01], :exclusive),
      Datespan.infinite_up(~D[2001-01-01], :exclusive))

    # Not strictly necessary - confirmation test
    assert Datespan.equal?(
      Datespan.infinite_up(~D[2001-01-01], :inclusive),
      Datespan.infinite_up(~D[2001-01-01], :inclusive))

    refute Datespan.equal?(
      Datespan.infinite_up(~D[2001-01-01], :exclusive),
      Datespan.infinite_up(~D[2001-01-01], :inclusive))

    # Not strictly necessary - confirmation test
    refute Datespan.equal?(
      Datespan.infinite_up(~D[2111-11-11], :inclusive),
      Datespan.infinite_up(~D[2001-01-01], :inclusive))
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
    query = from s in Reservation, where: contains(s.timespan, ^range)
    Sql.exists?(query, @institution)
  end
  
  defp db_overlaps?(timespan) do
    {:ok, range} = timespan |> Timespan.dump
    query = from s in Reservation, where: overlaps(s.timespan, ^range)
    Sql.exists?(query, @institution)
  end
  
  defp add_reservation!(timespan) do
    reservation = %Reservation{species_id: @bovine_id, timespan: timespan}
    Sql.insert!(reservation, @institution)
  end
end
