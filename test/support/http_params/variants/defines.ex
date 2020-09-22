defmodule Crit.Params.Variants.Defines do

  defmacro __using__(_) do
    quote do
      use Crit.Errors
      use Crit.TestConstants
      import Crit.Params.Build
      use FlowAssertions.Define
      use Crit.Params.Validate
      use Crit.Params.Exemplar

      def module_under_test(), do: test_data().module_under_test

      def check_form_validation(opts) do
        Validations.check_form_validation(test_data(), &accept_form/1, opts)
      end

      def check_exampler_changeset(pairs) do
        Validations.check_exampler_changeset(test_data(), pairs)
      end
    end
  end
end
  
