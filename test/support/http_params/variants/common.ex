defmodule Crit.Params.Variants.Common do

  defmacro __using__(_) do
    quote do
      use Crit.Errors
      use Crit.TestConstants
      import ExUnit.Assertions
      import Crit.Params.Build, only: [to_strings: 1, build: 1, like: 2]
      alias Crit.Params.Builder
      alias Crit.Params.Validation
      import Crit.Assertions.{Ecto,Map}

      def config(), do: __MODULE__.test_data()
      def config(:all_names), do: Map.keys(config(:data))
      def config(atom), do: config()[atom]

      def validate_changeset(name, changeset),
        do: Validation.validate_changeset(config(), changeset, name)

      def as_cast(descriptor, opts \\ []) do
        Validation.as_cast(config(), descriptor, opts)
      end

      def validate_categories(categories, function_runner, verbose \\ false) do
        exemplar_names =
          Validation.filter_by_categories(config(), categories, verbose)

        for name <- exemplar_names do 
          Validation.note_name(name, verbose)

          Validation.check_actual(
            config(),
            (make_params_for_name(config(), name) |> function_runner.()),
            name)
        end
      end

      # Convenience
      def validate_category(category, function_runner, verbose \\ false) do 
        validate_categories([category], function_runner, verbose)
      end

      def validate_lowered_values(descriptor) do
        Validation.assert_lowered(config(), descriptor, lower_changesets(descriptor))
      end        
    end
  end
end
  
