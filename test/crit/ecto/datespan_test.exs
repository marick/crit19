defmodule Crit.Ecto.DateSpanTest do
  use Crit.DataCase
  alias Ecto.Datespan
  import Ecto.Datespan
  alias Crit.Usables.{ScheduledUnavailability}
  alias Crit.Exemplars.Minimal
  alias Crit.Sql


  defp animal_with(datespan) do
    unavailability = %ScheduledUnavailability{
      datespan: datespan,
      reason: "no reason given"
    }
      
    Minimal.animal(scheduled_unavailabilities: [unavailability])
  end

  @day      ~D[2000-01-02]
  @prev_day ~D[2000-01-01]
  @next_day ~D[2000-01-03]
  @long_ago    ~D[1990-01-01]
  @far_forward ~D[2990-01-01]

  defp db_contains?(datespan) do
    {:ok, range} = datespan |> Datespan.dump
    query = from s in ScheduledUnavailability, where: contains(s.datespan, ^range)
    Sql.exists?(query, @default_short_name)
  end
  
  defp db_overlaps?(datespan) do
    {:ok, range} = datespan |> Datespan.dump
    query = from s in ScheduledUnavailability, where: overlaps(s.datespan, ^range)
    Sql.exists?(query, @default_short_name)
  end
  
  test "infinite down && containment" do
    database_span = Datespan.infinite_down(@day, :exclusive)
    animal_with(database_span)
    
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
    database_span = Datespan.infinite_down(@day, :exclusive)
    animal_with(database_span)

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
    database_span = Datespan.infinite_up(@day, :exclusive)
    animal_with(database_span)

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
    database_span = Datespan.infinite_up(@day, :exclusive)
    animal_with(database_span)

    refute db_overlaps?(Datespan.infinite_down(@day, :inclusive))
    assert db_overlaps?(Datespan.infinite_down(@next_day, :inclusive))
    refute db_overlaps?(Datespan.infinite_down(@next_day, :exclusive))
    
    refute db_overlaps?(Datespan.customary(@day, @next_day))
    refute db_overlaps?(Datespan.customary(@prev_day, @day))
  end

  test "inclusive infinite up" do
    database_span = Datespan.infinite_up(@day, :inclusive)
    animal_with(database_span)

    assert db_contains?(Datespan.infinite_up(@day, :exclusive))

    assert db_contains?(Datespan.customary(@day, @next_day))


    refute db_overlaps?(Datespan.customary(@long_ago, @day))
    assert db_overlaps?(Datespan.customary(@long_ago, @next_day))
  end

  test "customary" do
    database_span = Datespan.customary(@day, @next_day)
    animal_with(database_span)

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
