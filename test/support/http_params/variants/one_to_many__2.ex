defmodule Crit.Params.Variants.OneToMany2 do
  alias Crit.Params.{Get,Validate}
  use FlowAssertions.Ecto

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

  
  def that_are(test_data, descriptor), do: Get.params(test_data, descriptor)
  
  # ----------------------------------------------------------------------------
  
  def check_changeset(test_data, {:error, :form, changeset}, name) do
    assert_invalid(changeset)
    Validate.FormChecking.assert_error_expected(test_data, name)
    Validate.FormChecking.check(test_data, changeset, name)
  end
  
  def check_changeset(test_data, {:ok, changeset}, name) do
    assert_valid(changeset)
    Validate.FormChecking.refute_error_expected(test_data, name)
    Validate.FormChecking.check(test_data, changeset, name)
  end
  
  def make_params_for_name(test_data, name), do: Get.params(test_data, name)
end
