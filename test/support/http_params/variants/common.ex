defmodule Crit.Params.Variants.Common do

  defmacro __using__(_) do
    quote do
      use Crit.Errors
      use Crit.TestConstants
      import ExUnit.Assertions
      import Crit.Assertions.Defchain
      import Crit.Params.Build, only: [to_strings: 1, build: 1, like: 2]
      alias Crit.Params.Get
      alias Crit.Params.Validate
      alias Crit.Params.Validation
      import Crit.Assertions.{Ecto,Map}

      def config(), do: __MODULE__.test_data()
      def config(:all_names), do: Map.keys(config(:exemplars))
      def config(atom), do: config()[atom]

      def as_cast(descriptor, opts \\ []),
        do: Get.as_cast(config(), descriptor, opts)

      def cast_map(descriptor, opts \\ []),
        do: Get.cast_map(config(), descriptor, opts)

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



      
      defchain validate(:lowered, name),
        do: Validate.Lowering.check(config(), name, lower_changesets(name))

      defchain validate(:form_checking, name, changeset) do 
        Validate.FormChecking.check(config(), changeset, name)
      end
    end
  end
end
  
