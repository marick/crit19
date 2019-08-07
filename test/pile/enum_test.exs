defmodule Pile.EnumTest do
  use ExUnit.Case, async: true
  alias Pile.Enum

  def equals(n) do
    fn x -> x == n end
  end

  describe "extract" do
    test "splits into an element and the remainder of the list" do
      assert {1, [2, 3]} = Enum.extract([1, 2, 3], equals(1))
      assert {2, [1, 3]} = Enum.extract([1, 2, 3], equals(2))
      assert {3, [1, 2]} = Enum.extract([1, 2, 3], equals(3))
    end

    test "works with singleton list" do
      assert {1, []} = Enum.extract([1], equals(1))
    end

    test "caller responsibility that element be in the list exactly once" do
      catch_error Enum.extract([1, 2, 3], equals(999))
      catch_error Enum.extract([1, 2, 3, 2], equals(2))
    end
  end
end
  
