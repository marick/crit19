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

  defmacro __using__(
    module_under_test: module_under_test,
    default_cast_fields: default_cast_fields,
    data: data
  ) do 
    quote do
      use Crit.TestConstants
      import ExUnit.Assertions
      alias Ecto.Changeset
      import Crit.Params.Builder, only: [to_strings: 1]
      alias Crit.Params.Builder
      import Crit.Assertions.Changeset
      alias Crit.Params.Validation
      
      def data(), do: unquote(data)
      def default_cast_fields, do: unquote(default_cast_fields)
      def module_under_test, do: unquote(module_under_test)
      def all_names(), do: Map.keys(data())

      def validate_categories(categories, function_runner, verbose \\ false) do 
        Process.put(:data_source, __MODULE__)
        exemplar_names =
          Validation.filter_by_categories(all_names(), categories, verbose)

        for name <- exemplar_names do 
          Validation.note_name(name, verbose)

          Builder.only(name)
          |> function_runner.()
          |> Validation.check_actual(name)
        end          
      end

      # Convenience
      def validate_category(category, function_runner, verbose \\ false) do 
        validate_categories([category], function_runner, verbose)
      end

      def as_cast(descriptor, opts \\ []) do
        IO.inspect "hi"
        Process.put(:data_source, __MODULE__)
        Validation.as_cast(descriptor, opts)
      end


      # ----------------------------------------------------------------------------
      def that_are(descriptor) do
        Process.put(:data_source, __MODULE__)
        Builder.only(descriptor)
      end
    end
  end  
end
