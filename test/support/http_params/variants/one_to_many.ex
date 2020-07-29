defmodule Crit.Params.Variants.OneToMany do
  @moduledoc """
  A builder for controller params of this form:

  %{
    "names" => ...    <--- the "split field"
    "more" => ...,
    ...
  }

  The result of processing is the creation of N rows. The split field
  is processed to (eventually) create N rows in the database, one for
  each value of the *split field*. The split field may be an array of
  values (from, for example, an array of radio buttons) or a comma-separated
  string. Each record will have identical copies of all the non-split field
  values.

  In addition, the *split destination field* will have one of the
  values from the original split field. For example, the "names" split field
  would be used to fill in the "name" split destination field for each of the
  N resulting records.
  """

  defmacro __using__(_) do 
    quote do
      use Crit.Params.Variants.Common
      alias Crit.Params.{Get,Validate}
      import Crit.Assertions.Changeset
      
      defp make_params_for_name(config, name), do: Get.params(config(), name)
      def that_are(descriptor), do: Get.params(config(), descriptor)

      def check_changeset({:error, :form, changeset}, name) do
        config = config()
        assert_invalid(changeset)
        Validate.FormChecking.assert_error_expected(config, name)
        Validate.FormChecking.check(config, changeset, name)
      end

      def check_changeset({:ok, changeset}, name) do
        config = config()
        assert_valid(changeset)
        Validate.FormChecking.refute_error_expected(config, name)
        Validate.FormChecking.check(config(), changeset, name)
      end
    end
  end  
end
