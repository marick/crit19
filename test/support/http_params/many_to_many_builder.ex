defmodule Crit.Params.ManyToManyBuilder do
  @moduledoc """
  A builder for controller params of this form:

  %{
    "0" => %{...},
    "1" => %{...},
    ...
  }
  """

  defmacro __using__(_) do
    quote do
      use Crit.TestConstants
      use Crit.Errors
      import ExUnit.Assertions
      import Crit.Assertions.{Ecto,Map}
      alias Ecto.Changeset
      import Crit.Params.Builder, only: [to_strings: 1]
      alias Crit.Params.Builder
      import Crit.Assertions.Changeset
      alias Crit.Params.Validation

      def config(), do: __MODULE__.test_data()
      def data(), do: config().data
      def default_cast_fields, do: config().default_cast_fields
      def module_under_test, do: config().module_under_test
      def all_names(config), do: Map.keys(config.data)

      # ----------------------------------------------------------------------------
      def validate_categories(categories, function_runner, verbose \\ false) do
        exemplar_names =
          Validation.filter_by_categories(config(), all_names(config()), categories, verbose)

        for name <- exemplar_names do 
          Validation.note_name(name, verbose)

          Validation.check_actual(
            config(),
            (Builder.make_numbered_params(config(), [name]) |> function_runner.()),
            name)
          
        end
      end

      # Convenience
      def validate_category(category, function_runner, verbose \\ false) do 
        validate_categories([category], function_runner, verbose)
      end

      # ----------------------------------------------------------------------------
      #

      def validate_lowered_values(descriptor) do
        config = config()
        exemplar = Builder.one_value(config, descriptor)
        [{field_to_split, destination_field}] = Enum.into(config.splits, [])
        actuals = lower_changesets(descriptor)

        split_cast_values = Keyword.get(as_cast(descriptor), field_to_split)
        
        for struct <- actuals do
          cast_map = Enum.into(as_cast(descriptor), %{})
          
          struct
          |> assert_schema(config.produces)
          |> assert_partial_copy(cast_map, config.retains)
        end

        for {struct, split_value} <- Enum.zip(actuals, split_cast_values) do
          assert Map.get(struct, destination_field) == split_value
        end
        
      end

      # ----------------------------------------------------------------------------
      def as_cast(descriptor, opts \\ []) do
        Validation.as_cast(config(), descriptor, opts)
      end

      # ----------------------------------------------------------------------------
      def that_are(descriptors) when is_list(descriptors) do
        Builder.make_numbered_params(config(), descriptors)
      end
  
      def that_are(descriptor),       do: that_are([descriptor])
      def that_are(descriptor, opts), do: that_are([[descriptor | opts]])
    end
  end  
end
