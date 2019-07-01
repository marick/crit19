defmodule Ecto2.TimespanTest do
  use ExUnit.Case, async: true
  alias Ecto2.Timespan

  @early Faker.NaiveDateTime.backward(20)
  @later Faker.NaiveDateTime.forward(20)

  test "basic creation" do
    assert Timespan.new(@early, @later, true, false) ==
      %Timespan{
        first: @early,
        last: @later,
        lower_inclusive: true,
        upper_inclusive: false,
      }

    # Note that nonsensical timespans *are* allowed.
    # (It happens that Postgres will produce an error.)
    assert Timespan.new(@later, @early, true, false) ==
      %Timespan{
        first: @later,
        last: @early,
        lower_inclusive: true,
        upper_inclusive: false,
      }

    # :unbounds are allowed and represent unbounded past or future
    
    assert Timespan.new(:unbound, :unbound, false, true) ==
      %Timespan{
        first: :unbound,
        last: :unbound,
        lower_inclusive: false,
        upper_inclusive: true,
      }


    # Dates are converted

    first_tuple = Date.to_erl(@early)
    second_tuple = Date.to_erl(@later)

    first_date =  Date.from_erl!(first_tuple)
    second_date = Date.from_erl!(second_tuple)
    
    expected_first = NaiveDateTime.from_erl!({first_tuple, {0, 0, 0}})
    expected_second = NaiveDateTime.from_erl!({second_tuple, {0, 0, 0}})

    actual = Timespan.new(first_date, second_date, false, true)

    assert :eq == NaiveDateTime.compare(actual.first, expected_first)
    assert :eq == NaiveDateTime.compare(actual.last, expected_second)
  end


  test "variant ways of creating" do
    assert Timespan.infinite_down(@early, :inclusive) == Timespan.new(:unbound, @early, false, true)
    assert Timespan.infinite_down(@early, :exclusive) == Timespan.new(:unbound, @early, false, false)
    
    assert Timespan.infinite_up(@later, :inclusive) == Timespan.new(@later, :unbound, true, false)
    assert Timespan.infinite_up(@later, :exclusive) == Timespan.new(@later, :unbound, false, false)

    # The most common timespan is inclusive on the bottom, exclusive at the top.
    assert Timespan.customary(@early, @later) == Timespan.new(@early, @later, true, false)

    assert Timespan.for_instant(@early) == Timespan.new(@early, @early, true, true)

    assert Timespan.plus(~N{2001-02-03 12:04:00}, 1, :minute) ==
      Timespan.customary(~N{2001-02-03 12:04:00},
                         ~N{2001-02-03 12:05:00})
  end


  test "round-tripping to database format" do
      assert :error == Timespan.cast("bad value")
      assert :error == Timespan.load("bad value")


      round_trip = fn(original) ->
        {:ok, roundtripped} = original |> Timespan.dump |> elem(1) |> Timespan.load
        assert original == roundtripped
      end
      
      round_trip.(Timespan.customary(@early, @later))
      round_trip.(Timespan.infinite_up(@early, :inclusive))
      round_trip.(Timespan.infinite_down(@later, :exclusive))
  end
  
end