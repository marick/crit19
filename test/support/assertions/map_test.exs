defmodule Crit.Assertions.MapTest do
  use ExUnit.Case, async: true
  import Crit.Assertions.Map

  @under_test %{field1: 1, field2: 2, list: [1, 2], empty: []}

  describe "`assert_fields` with keyword lists" do
    test "assertion failure" do 
      assert_raise ExUnit.AssertionError, fn -> 
        assert_fields(@under_test, field1: 1,  missing_field: 5)
      end
    end

    test "how a bad value is reported" do
      exception = assert_raise ExUnit.AssertionError, fn -> 
        assert_fields(@under_test, field1: 1,  field2: 3838)
      end

      assert exception.message =~ "`:field2` has the wrong value"
      assert exception.message =~ "actual:   2"
      assert exception.message =~ "expected: 3838"
    end
        
    test "no failure returns value being tested" do 
      result = assert_fields(@under_test, field1: 1)
      assert @under_test == result
    end

    test "note that the field must actually be present" do
      # We don't check the default.
      exception = assert_raise ExUnit.AssertionError, fn -> 
        assert_fields(@under_test, missing_field: nil)
      end
      assert exception.message == "Field `:missing_field` is missing"
    end

    test "can check a field against a predicate" do
      # pass
      assert @under_test == assert_fields(@under_test, empty: &Enum.empty?/1)

      # fail
      assert_raise ExUnit.AssertionError, fn ->
        assert_fields(@under_test, list: &Enum.empty?/1)
      end
    end

    test "how bad predicate values are printed" do
      exception = assert_raise ExUnit.AssertionError, fn ->
        assert_fields(@under_test, list: &Enum.empty?/1)
      end
      assert exception.message == ":list => [1, 2] fails predicate &Enum.empty?/1"
    end
  end

  describe "`assert_fields` with just a list of fields" do
    test "assertion failure" do 
      assert_raise ExUnit.AssertionError, fn -> 
        assert_fields(@under_test, [:field1, :missing_field])
      end
    end
        
    test "how failure is reported" do 
      exception = assert_raise ExUnit.AssertionError, fn -> 
        assert_fields(@under_test, [:field1, :missing_field])
      end

      assert exception.message == "Field `:missing_field` is missing"
    end

    test "no failure returns value being tested" do 
      result = assert_fields(@under_test, [:field1])
      assert @under_test == result
    end

    test "`nil` and `false` are valid values." do
      input = %{nil_field: nil, false_field: false}
      assert_fields(input, [:nil_field, :false_field])
    end
  end

  describe "`assert_field`" do
    test "usefulness for the grammar pedant" do 
      assert_field(@under_test, field1: 1)
    end

    test "you can use a singleton value to test field presence" do
      exception = assert_raise ExUnit.AssertionError, fn -> 
        assert_field(@under_test, :missing_field)
      end

      assert exception.message == "Field `:missing_field` is missing"
    end
  end


  describe "`assert_copy`" do
    test "can ignore fields" do
      left =  %{field1: 1, field2: 2}
      right = %{field1: 1, field2: 22222}
      assert_raise ExUnit.AssertionError, fn ->
        assert left == right
      end

      assert_copy(left, right, except: [:field2])
    end
  end
end

