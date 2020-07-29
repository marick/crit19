defmodule Crit.Params.Validate do
  import ExUnit.Assertions
  import Crit.Assertions.{Ecto,Map}
  alias Pile.Namelist
  alias Crit.Params.Get

  defmodule FormChecking do
    import Crit.Assertions.Changeset

    def assert_error_expected(config, name) do
      exemplar = Get.exemplar(config, name)
      assert Map.has_key?(exemplar, :errors)
    end
    
    def refute_error_expected(config, name) do
      exemplar = Get.exemplar(config, name)
      refute Map.has_key?(exemplar, :errors)
    end
    
    def check(config, changeset, descriptor) do
      item = Get.exemplar(config, descriptor)
      if Map.has_key?(item, :verbose) do
        IO.inspect(item.params, label: to_string(descriptor))
        IO.inspect(changeset, label: "changeset")
        IO.inspect(changeset.data, label: "underlying data")
      end
      
      assert changeset.valid? == Enum.member?(item.categories, :valid)
      
      unchanged_fields = Map.get(item, :unchanged, [])
      errors = Map.get(item, :errors, [])
      
      changeset
      |> assert_change(Get.as_cast(config, descriptor, without: unchanged_fields))
      |> assert_unchanged(unchanged_fields)
      |> assert_errors(errors)
    end
  end
  
  # ----------------------------------------------------------------------------
  defmodule Lowering do
    def check(config, descriptor, actuals) do
      assert_non_split_values(config, descriptor, actuals)
      assert_split_value(config, descriptor, actuals)
    end
    
    defp assert_non_split_values(config, descriptor, actuals) do 
      for struct <- actuals do
        cast_map = Get.cast_map(config, descriptor)
        
        struct
        |> assert_schema(config.produces)
        |> assert_partial_copy(cast_map, config.lowering_retains)
      end
    end
    
    defp assert_split_value(config, descriptor, actuals) do
      [{field_to_split, destination_field}] = Enum.into(config.lowering_splits, [])
      split_cast_values = split(Get.as_cast(config, descriptor), field_to_split)
      
      for {struct, split_value} <- Enum.zip(actuals, split_cast_values),
        do: assert Map.get(struct, destination_field) == split_value
    end
    
    defp split(cast_values, field_to_split),
      do: Keyword.get(cast_values, field_to_split) |> split_value
    
    defp split_value(value) when is_list(value), do: value
    defp split_value(value) when is_binary(value), do: Namelist.to_list(value)
  end
end
