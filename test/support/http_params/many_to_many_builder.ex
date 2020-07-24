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
      import ExUnit.Assertions
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
        
        # Process.put(:data_source, __MODULE__)
        # expected = Builder.one_value(descriptor) |> IO.inspect
        # actuals = lower_changesets(descriptor) |> IO.inspect
        # for value <- actuals do
        #   value
        #   |> IO.inspect
        # end
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
