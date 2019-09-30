defmodule Crit.Ecto.DateSpanTest do
  use Crit.DataCase
  alias Ecto.Datespan
  import Ecto.Datespan
  alias Crit.Usables.Write.ServiceGap  # Convenient for testing
  alias Crit.Sql

  
  defp insert_service_gap(datespan) do
    Sql.insert!(%ServiceGap{
      gap: datespan,
      reason: "no reason given"
    }, @institution)
  end

  @day      ~D[2000-01-02]
  @prev_day ~D[2000-01-01]
  @next_day ~D[2000-01-03]
  @long_ago    ~D[1990-01-01]
  @far_forward ~D[2990-01-01]

  defp db_contains?(datespan) do
    {:ok, range} = datespan |> Datespan.dump
    query = from s in ServiceGap, where: contains(s.gap, ^range)
    Sql.exists?(query, @institution)
  end
  
  defp db_overlaps?(datespan) do
    {:ok, range} = datespan |> Datespan.dump
    query = from s in ServiceGap, where: overlaps(s.gap, ^range)
    Sql.exists?(query, @institution)
  end

  test "shorthand: strictly_before" do
    span = Datespan.strictly_before(@day)
    assert_same_date(span, Datespan.infinite_down(@day, :exclusive))
    assert_strictly_before(span, @day)
  end
  
  test "shorthand: date_and_after" do
    span = Datespan.date_and_after(@day)
    assert_same_date(span, Datespan.infinite_up(@day, :inclusive))
    assert_date_and_after(span, @day)
  end

  test "type tests" do 
    infinite_down = Datespan.infinite_down(@day, :inclusive)
    assert Datespan.infinite_down?(infinite_down)
    refute Datespan.infinite_up?(infinite_down)

    infinite_down_e = Datespan.infinite_down(@day, :exclusive)
    assert Datespan.infinite_down?(infinite_down_e)
    refute Datespan.infinite_up?(infinite_down_e)

    infinite_up = Datespan.infinite_up(@day, :inclusive)
    refute Datespan.infinite_down?(infinite_up)
    assert Datespan.infinite_up?(infinite_up)

    infinite_up_e = Datespan.infinite_up(@day, :exclusive)
    refute Datespan.infinite_down?(infinite_up_e)
    assert Datespan.infinite_up?(infinite_up_e)

    customary = customary(@day, @next_day)
    refute Datespan.infinite_down?(customary)
    refute Datespan.infinite_up?(customary)
  end

    
  test "infinite down && containment" do
    insert_service_gap(Datespan.infinite_down(@day, :exclusive))
    
    assert db_contains?(Datespan.infinite_down(@day, :exclusive))
    assert db_contains?(Datespan.infinite_down(@prev_day, :exclusive))
    refute db_contains?(Datespan.infinite_down(@next_day, :exclusive))

    refute db_contains?(Datespan.infinite_down(@day, :inclusive))
    assert db_contains?(Datespan.infinite_down(@prev_day, :inclusive))
    refute db_contains?(Datespan.infinite_down(@next_day, :inclusive))

    assert db_contains?(Datespan.customary(@long_ago, @prev_day))
    assert db_contains?(Datespan.customary(@long_ago, @day))
    refute db_contains?(Datespan.customary(@long_ago, @next_day))

    refute db_contains?(Datespan.infinite_up(@long_ago, :inclusive))
    refute db_contains?(Datespan.infinite_up(@long_ago, :exclusive))
  end

  test "infinite down && overlap" do
    insert_service_gap(Datespan.infinite_down(@day, :exclusive))

    refute db_overlaps?(Datespan.customary(@day, @far_forward))
    assert db_overlaps?(Datespan.customary(@prev_day, @far_forward))

    refute db_overlaps?(Datespan.infinite_up(@day, :inclusive))
    assert db_overlaps?(Datespan.infinite_up(@prev_day, :inclusive))

    refute db_overlaps?(Datespan.infinite_up(@prev_day, :exclusive))

    assert db_overlaps?(Datespan.infinite_down(@day, :inclusive))
    assert db_overlaps?(Datespan.infinite_down(@prev_day, :inclusive))
    assert db_overlaps?(Datespan.infinite_down(@next_day, :inclusive))
    
    assert db_overlaps?(Datespan.infinite_down(@day, :exclusive))
    assert db_overlaps?(Datespan.infinite_down(@prev_day, :exclusive))
    assert db_overlaps?(Datespan.infinite_down(@next_day, :exclusive))
  end

  test "infinite up and containment" do
    insert_service_gap(Datespan.infinite_up(@day, :exclusive))

    assert db_contains?(Datespan.infinite_up(@day, :exclusive))
    refute db_contains?(Datespan.infinite_up(@prev_day, :exclusive))
    assert db_contains?(Datespan.infinite_up(@next_day, :exclusive))
    
    refute db_contains?(Datespan.infinite_up(@day, :inclusive))
    refute db_contains?(Datespan.infinite_up(@prev_day, :inclusive))
    assert db_contains?(Datespan.infinite_up(@next_day, :inclusive))

    refute db_contains?(Datespan.infinite_down(@far_forward, :inclusive))

    refute db_contains?(Datespan.customary(@day, @next_day))
    assert db_contains?(Datespan.customary(@next_day, @far_forward))
  end
  
  test "infinite up and overlap" do
    insert_service_gap(Datespan.infinite_up(@day, :exclusive))

    refute db_overlaps?(Datespan.infinite_down(@day, :inclusive))
    assert db_overlaps?(Datespan.infinite_down(@next_day, :inclusive))
    refute db_overlaps?(Datespan.infinite_down(@next_day, :exclusive))
    
    refute db_overlaps?(Datespan.customary(@day, @next_day))
    refute db_overlaps?(Datespan.customary(@prev_day, @day))
  end

  test "inclusive infinite up" do
    insert_service_gap(Datespan.infinite_up(@day, :inclusive))

    assert db_contains?(Datespan.infinite_up(@day, :exclusive))

    assert db_contains?(Datespan.customary(@day, @next_day))


    refute db_overlaps?(Datespan.customary(@long_ago, @day))
    assert db_overlaps?(Datespan.customary(@long_ago, @next_day))
  end

  test "customary" do
    insert_service_gap(Datespan.customary(@day, @next_day))

    assert db_contains?(Datespan.customary(@day, @next_day))
    assert db_overlaps?(Datespan.customary(@day, @next_day))
    
    refute db_contains?(Datespan.customary(@day, @far_forward))
    assert db_overlaps?(Datespan.customary(@day, @far_forward))
    
    refute db_contains?(Datespan.customary(@prev_day, @day))
    refute db_overlaps?(Datespan.customary(@prev_day, @day))

    refute db_contains?(Datespan.infinite_down(@far_forward, :inclusive))
    assert db_overlaps?(Datespan.infinite_down(@far_forward, :inclusive))
    refute db_overlaps?(Datespan.infinite_down(@day, :exclusive))
    assert db_overlaps?(Datespan.infinite_down(@day, :inclusive))

    refute db_overlaps?(Datespan.infinite_up(@next_day, :inclusive))
  end
end
