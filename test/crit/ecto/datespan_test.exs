defmodule Crit.Ecto.DateSpanTest do
  use Crit.DataCase
  import Ecto.Datespan

  describe "put_last" do 
    test "infinite up" do
      actual =
        inclusive_up(@date_1)
        |> put_last(@date_2)
      assert actual == customary(@date_1, @date_2)
    end

    test "customary" do
      actual =
        customary(@date_1, next_day(@date_1))
        |> put_last(@date_2)
      assert actual == customary(@date_1, @date_2)
    end
  end

  test "is_customary?" do
    assert is_customary?(customary(@date_1, @date_2))
    refute is_customary?(infinite_up(@date_1, :exclusive))
    refute is_customary?(infinite_up(@date_1, :inclusive))

    true? = fn first, last, lower_inclusive, upper_inclusive ->
      new(first, last, lower_inclusive, upper_inclusive)
      |> is_customary?
    end

    refute true?.(@date_1, @date_2, false, false)
    refute true?.(@date_1, @date_2, false, true)
    assert true?.(@date_1, @date_2, true, false)
    refute true?.(@date_1, @date_2, true, true)
            
    refute true?.(@date_1, :unbound, false, false)
    refute true?.(@date_1, :unbound, true, false)

    refute true?.(:unbound, @date_2, false, false)
    refute true?.(:unbound, @date_2, true, false)
  end

  # `first_to_string` is not intended for infinite-down spans
  test "first_to_string" do
    assert first_to_string(customary(@date_1, @date_2)) == @iso_date_1
    assert first_to_string(infinite_up(@date_1, :exclusive)) == @iso_date_1
  end

  test "last_to_string" do
    assert last_to_string(customary(@date_1, @date_2)) == @iso_date_2
    assert last_to_string(infinite_up(@date_1, :exclusive)) == @never
  end

  test "inclusive_up" do
    assert inclusive_up(@date_1) == infinite_up(@date_1, :inclusive)
  end
  
end
