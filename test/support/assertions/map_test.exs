defmodule Crit.Assertions.MapTest do
  use ExUnit.Case, async: true
  import Crit.Assertions.{Map, Assertion}

  defstruct name: nil # Used for typo testing

  @under_test %{field1: 1, field2: 2, list: [1, 2], empty: []}

  describe "`assert_fields` with keyword lists" do
    test "assertion failure" do
      assertion_fails_with_diagnostic(
        "Field `:missing_field` is missing",
        fn -> 
          assert_fields(@under_test, field1: 1,  missing_field: 5)
        end)
    end

    test "how a bad value is reported" do
      assertion_fails_with_diagnostic(
        ["`:field2` has the wrong value",
         "actual:   2",
         "expected: 3838"],
        fn -> 
          assert_fields(@under_test, field1: 1,  field2: 3838)
        end)
    end
        
    test "no failure returns value being tested" do 
      result = assert_fields(@under_test, field1: 1)
      assert @under_test == result
    end

    test "note that the field must actually be present" do
      # We don't use Map.get with a default.
      assertion_fails_with_diagnostic(
        "Field `:missing_field` is missing",
        fn ->
          assert_fields(@under_test, missing_field: nil)
        end)
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
      assertion_fails_with_diagnostic(
        ":list => [1, 2] fails predicate &Enum.empty?/1",
        fn ->
          assert_fields(@under_test, list: &Enum.empty?/1)
        end)
    end
  end

  describe "`assert_fields` with just a list of fields" do
    test "how failure is reported" do
      assertion_fails_with_diagnostic(
        "Field `:missing_field` is missing",
        fn -> 
          assert_fields(@under_test, [:field1, :missing_field])
      end)
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
      assertion_fails_with_diagnostic(
        "Field `:missing_field` is missing",
        fn -> 
          assert_field(@under_test, :missing_field)
        end)
    end
  end

  describe "typo protection" do
    test "... is possible in a struct" do
      struct = %__MODULE__{name: "hello"}

      assertion_fails_with_diagnostic(
        "Test error: there is no key `:typo` in Crit.Assertions.MapTest",
        fn ->
          assert_field(struct, :typo)
        end)

      assertion_fails_with_diagnostic(
        "Test error: there is no key `:typo` in Crit.Assertions.MapTest",
        fn ->
          assert_field(struct, typo: 5)
        end)

      # It doesn't spuriously fail.
      # (Everywhere else in this file, we use maps.)
      assert_field(struct, :name)

      # It doesn't fail on maps *for this reason*.
      assertion_fails_with_diagnostic(
        "Field `:typo` is missing",
        fn -> 
          assert_field(%{name: 3}, typo: 3)
        end)
    end
  end


  describe "`assert_copy`" do
    test "can ignore fields" do
      left =  %{field1: 1, field2: 2}
      right = %{field1: 1, field2: 22222}

      # Here, for reference is what plain equality does:
      assert_raise(ExUnit.AssertionError, fn -> 
        assert left == right
      end)
      |> assert_fields(left: left,
                       right: right,
                       message: "Assertion with == failed")

      # No error
      assert_copy(left, right, except: [:field2])

      # Assert_copy fails the same way `assert ==` does
      # except note that it doesn't mention `except` fields
      assert_raise(ExUnit.AssertionError, fn -> 
        assert_copy(left, right, except: [:field1])
      end)
      |> assert_fields(left: %{field2: 2},
                       right: %{field2: 22222},
                       message: "Assertion with == failed")
    end
  end
end

