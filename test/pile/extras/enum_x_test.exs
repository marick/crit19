defmodule EnumXTest do
  use ExUnit.Case, async: true

  def equals(n) do
    fn x -> x == n end
  end

  describe "extract" do
    test "splits into an element and the remainder of the list" do
      assert {1, [2, 3]} = EnumX.extract([1, 2, 3], equals(1))
      assert {2, [1, 3]} = EnumX.extract([1, 2, 3], equals(2))
      assert {3, [1, 2]} = EnumX.extract([1, 2, 3], equals(3))
    end

    test "works with singleton list" do
      assert {1, []} = EnumX.extract([1], equals(1))
    end

    test "caller responsibility that element be in the list exactly once" do
      catch_error EnumX.extract([1, 2, 3], equals(999))
      catch_error EnumX.extract([1, 2, 3, 2], equals(2))
    end
  end

  test "sort_by_id" do
    input = [%{id: 3}, %{id: 1}, %{id: 2}]
    expected = [%{id: 1}, %{id: 2}, %{id: 3}]
    assert EnumX.sort_by_id(input) == expected
  end

  test "extract ids (and sort them)" do
    input = [%{id: 3}, %{id: 1}, %{id: 2}]
    expected = [1, 2, 3]
    assert EnumX.ids(input) == expected
  end

  test "pairs" do
    input = [ %{name: "bossie", id: 1, extra: "stuff"},
              %{name: "jake", id: 2, extra: "stuff"}
            ]
    expected = [{"bossie", 1}, {"jake", 2}]
    assert expected == EnumX.pairs(input, :name, :id)
  end

  test "find_id" do
    bossie = %{name: "bossie", id: 1, extra: "stuff"}
    input = [ bossie,
              %{name: "jake", id: 2, extra: "stuff"}
            ]
    assert bossie == EnumX.find_by_id(input, 1)
  end
  
end
  
