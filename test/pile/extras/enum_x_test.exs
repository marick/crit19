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

  test "to_id_map" do
    input = [ %{name: "bossie", id: 1, extra: "stuff"},
              %{name: "jake", id: 2, extra: "stuff"}
            ]
    expected = %{1 => "bossie", 2 => "jake"}
    assert expected == EnumX.to_id_map(input, :name)
  end

  describe "cross_product" do
    test "without optional args" do
      actual = EnumX.cross_product([1, 2, 3], ["a", "b", "c"])
      expected = [
        {1, "a"}, {1, "b"}, {1, "c"},  
        {2, "a"}, {2, "b"}, {2, "c"},  
        {3, "a"}, {3, "b"}, {3, "c"}
      ]
      assert actual == expected
    end

    test "with functional optional args" do
      actual =
        EnumX.cross_product([1, 2, 3], ["a", "b", "c"],
          &(&1+1), &String.upcase/1)
      expected = [
        {2, "A"}, {2, "B"}, {2, "C"},  
        {3, "A"}, {3, "B"}, {3, "C"},  
        {4, "A"}, {4, "B"}, {4, "C"}
      ]
      assert actual == expected
    end

    test "with atoms for structure access" do
      actual =
        EnumX.cross_product(
          [%{id: 1},     %{id: 2},     %{id: 3}],
          [%{name: "A"}, %{name: "B"}, %{name: "C"}],
          :id, :name)
      expected = [
        {1, "A"}, {1, "B"}, {1, "C"},  
        {2, "A"}, {2, "B"}, {2, "C"},  
        {3, "A"}, {3, "B"}, {3, "C"}
      ]
      assert actual == expected
    end

    test "filter_by_ids" do
      actual = 
        EnumX.filter_by_ids([%{id: 1}, %{id: 2}, %{id: 3}], [1,3])
      assert actual == [%{id: 1}, %{id: 3}]
    end
  end

  describe "pour_struct" do

    defmodule Smaller do
      defstruct common: nil
    end

    defmodule Larger do
      defstruct common: nil, unique: "unique default"
    end
    
    test "from larger to smaller" do
      actual = EnumX.pour_into(%Larger{common: "copied"}, Smaller)

      assert actual == %Smaller{common: "copied"}
    end


    test "from smaller to larger" do
      actual = EnumX.pour_into(%Smaller{common: "copied"}, Larger)

      assert actual == %Larger{common: "copied", unique: "unique default"}
    end
  end
end
  
