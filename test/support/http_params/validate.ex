defmodule Crit.Params.Validate do
  import ExUnit.Assertions
  use FlowAssertions
  use FlowAssertions.Ecto
  alias Pile.Namelist
  alias Crit.Params.Get
  use FlowAssertions.Define

  def note_name(name, verbose) do
    if verbose, do: IO.puts("+ #{inspect name}")
  end

  defmodule FormChecking do
    use FlowAssertions.Ecto
    import Mockery.Assertions

    def assert_error_expected(test_data, name) do
      exemplar = Get.exemplar(test_data, name)
      assert Map.has_key?(exemplar, :errors)
    end
    
    def refute_error_expected(test_data, name) do
      exemplar = Get.exemplar(test_data, name)
      refute Map.has_key?(exemplar, :errors)
    end

    def check(test_data, changeset, descriptor) do
      item = Get.exemplar(test_data, descriptor)

      try do 
        assert changeset.valid? == Enum.member?(item.categories, :valid)
        
        unchanged_fields = Map.get(item, :unchanged, [])
        errors = Map.get(item, :errors, [])

        changeset
        |> assert_change(Get.as_cast(test_data, descriptor, without: unchanged_fields))
        |> assert_no_changes(unchanged_fields)
        |> assert_errors(errors)
        check_spies(item[:because_of])
      rescue
        exception in [ExUnit.AssertionError] ->
          IO.puts "\nBackground for following test failure:"
          IO.inspect(item.params, label: to_string(descriptor))
          IO.inspect(changeset, label: "changeset")
          IO.inspect(changeset.data, label: "underlying data")
          reraise exception, __STACKTRACE__
      end
    end

    defp check_spies(dependencies) when is_list(dependencies) do
      for {module, name} <- dependencies do
        assert_called(module, name)
      end
    end
    
    defp check_spies(tuple) when is_tuple(tuple), do: check_spies([tuple])
    defp check_spies(_), do: "nothing"
  end
  
  # ----------------------------------------------------------------------------
  defmodule Lowering do
    def check(test_data, descriptor, actuals) do
      assert_non_split_values(test_data, descriptor, actuals)
      assert_split_value(test_data, descriptor, actuals)
    end
    
    defp assert_non_split_values(test_data, descriptor, actuals) do 
      for struct <- actuals do
        cast_map = Get.cast_map(test_data, descriptor)
        
        struct
        |> assert_schema_name(test_data.produces)
        |> assert_same_map(cast_map, comparing: test_data.lowering_retains)
      end
    end
    
    defp assert_split_value(test_data, descriptor, actuals) do
      [{field_to_split, destination_field}] = Enum.into(test_data.lowering_splits, [])
      split_cast_values = split(Get.as_cast(test_data, descriptor), field_to_split)
      
      for {struct, split_value} <- Enum.zip(actuals, split_cast_values),
        do: assert Map.get(struct, destination_field) == split_value
    end
    
    defp split(cast_values, field_to_split),
      do: Keyword.get(cast_values, field_to_split) |> split_value
    
    defp split_value(value) when is_list(value), do: value
    defp split_value(value) when is_binary(value), do: Namelist.to_list(value)
  end


  defmacro __using__(_) do
    quote do
      alias Crit.Params.Validate
      
      defchain validate(:form_checking, name, changeset) do 
        FormChecking.check(test_data(), changeset, name)
      end
      
      defchain validate(:lowered, name),
        do: Lowering.check(test_data(), name, lower_changesets(name))
    end
  end
end
