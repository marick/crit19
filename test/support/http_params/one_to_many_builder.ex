defmodule Crit.Params.OneToManyBuilder do
  @moduledoc """
  A builder for controller params of this form:

  %{
    "names" => "a, b, c"
    "more" => ...,
    ...
  }

  The result of processing is the creation of N rows.
  """

  defmacro __using__(_) do 
    quote do
      use Crit.TestConstants
      use Crit.Errors
      import ExUnit.Assertions
      alias Ecto.Changeset
      import Crit.Params.Builder, only: [to_strings: 1]
      alias Crit.Params.Builder
      import Crit.Assertions.Changeset
      alias Crit.Params.Validation
      
      def config(), do: __MODULE__.test_data()
      defp all_names(config), do: Map.keys(config().data)

      def validate_categories(categories, function_runner, verbose \\ false) do 
        exemplar_names =
          Validation.filter_by_categories(config(), all_names(config()), categories, verbose)

        for name <- exemplar_names do 
          Validation.note_name(name, verbose)

          Validation.check_actual(
            config(),
            (Builder.only(config(), name) |> function_runner.()),
            name)
        end          
      end

      # Convenience
      def validate_category(category, function_runner, verbose \\ false) do 
        validate_categories([category], function_runner, verbose)
      end

      def as_cast(descriptor, opts \\ []) do
        Validation.as_cast(config(), descriptor, opts)
      end

      # ----------------------------------------------------------------------------
      def that_are(descriptor) do
        Builder.only(config(), descriptor)
      end
    end
  end  
end
