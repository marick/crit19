defmodule Crit.Params.BuildTest do
  use ExUnit.Case, async: true
  import Crit.Params.Build

  describe "to_strings" do
    test "empty" do
      assert to_strings(%{}) == %{}
    end

    test "keys" do
      input = %{a: "a", b: "b"}
      expected = %{"a" => "a", "b" => "b"}
      assert to_strings(input) == expected
    end

    test "integer values are turned to strings" do
      input = %{a: 1, b: 2}
      expected = %{"a" => "1", "b" => "2"}
      assert to_strings(input) == expected
    end

    test "nested maps are descended" do
      input = %{a: 1, b: %{bb: 2}}
      expected = %{"a" => "1", "b" => %{"bb" => "2"}}

      assert to_strings(input) == expected
    end

    test "array values are turned into arrays of strings" do
      input = %{a: 1, b: [1, 2]}
      expected = %{"a" => "1", "b" => ["1", "2"]}
      assert to_strings(input) == expected
    end
  end
  
end
