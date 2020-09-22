defmodule Crit.Params.Variants.OneToMany2 do
  alias Crit.Params.Get
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

  
  def that_are(test_data, descriptors) when is_list(descriptors) do 
    Get.params(test_data, descriptors)
  end
  
  def make_params_for_name(test_data, name), do: Get.params(test_data, name)

  defmacro __using__(_) do
    quote do
      alias Crit.Params.Variants.OneToMany2, as: Variant
      use Crit.Params.Variants.Defines, Variant
    end
  end
end
