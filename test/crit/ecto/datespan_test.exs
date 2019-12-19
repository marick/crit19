defmodule Crit.Ecto.DateSpanTest do
  use Crit.DataCase
  import Ecto.Datespan

  describe "put_last" do 
    test "infinite up" do
      actual =
        inclusive_up(@date)
        |> put_last(@later_date)
      assert actual == customary(@date, @later_date)
    end

    test "customary" do
      actual =
        customary(@date, @bumped_date)
        |> put_last(@later_date)
      assert actual == customary(@date, @later_date)
    end
  end

  test "is_customary?" do
    assert is_customary?(customary(@date, @later_date))
    refute is_customary?(infinite_up(@date, :exclusive))
    refute is_customary?(infinite_up(@date, :inclusive))

    true? = fn first, last, lower_inclusive, upper_inclusive ->
      new(first, last, lower_inclusive, upper_inclusive)
      |> is_customary?
    end

    refute true?.(@date, @later_date, false, false)
    refute true?.(@date, @later_date, false, true)
    assert true?.(@date, @later_date, true, false)
    refute true?.(@date, @later_date, true, true)
            
    refute true?.(@date, :unbound, false, false)
    refute true?.(@date, :unbound, true, false)

    refute true?.(:unbound, @later_date, false, false)
    refute true?.(:unbound, @later_date, true, false)
  end

  # `first_to_string` is not intended for infinite-down spans
  test "first_to_string" do
    assert first_to_string(customary(@date, @later_date)) == @iso_date
    assert first_to_string(infinite_up(@date, :exclusive)) == @iso_date
  end

  test "last_to_string" do
    assert last_to_string(customary(@date, @later_date)) == @later_iso_date
    assert last_to_string(infinite_up(@date, :exclusive)) == @never
  end

  test "inclusive_up" do
    assert inclusive_up(@date) == infinite_up(@date, :inclusive)
  end
  
end
