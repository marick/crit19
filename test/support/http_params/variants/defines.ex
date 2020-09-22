defmodule Crit.Params.Variants.Defines do

  defmacro __using__(variant_module) do
    quote do
      use Crit.Errors
      use Crit.TestConstants
      import Crit.Params.Build
      use FlowAssertions.Define
      alias Crit.Params.{Get, Validations}

      def module_under_test(), do: test_data().module_under_test

      def check_form_validation(opts) do
        Validations.check_form_validation(test_data(), &accept_form/1, opts)
      end

      def check_exampler_changeset(pairs) do
        Validations.check_exampler_changeset(test_data(), pairs)
      end

      def check_form_lowering(name) do
        Validations.check_form_lowering(test_data(), name, &accept_and_lower/1)
      end

      def as_cast(descriptor, opts \\ []),
        do: Get.as_cast(test_data(), descriptor, opts)

      def cast_map(descriptor, opts \\ []),
        do: Get.cast_map(test_data(), descriptor, opts)

      def that_are(descriptors) when is_list(descriptors),
        do: unquote(variant_module).that_are(test_data(), descriptors)

      def that_are(descriptor), do: that_are([descriptor])
      def that_are(descriptor, opts), do: that_are([[descriptor | opts]])
    end
  end
end
  
