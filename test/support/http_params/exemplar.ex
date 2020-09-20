defmodule Crit.Params.Exemplar do
  alias Crit.Params.Get

  def as_cast(test_data, descriptor, opts \\ []),
    do: Get.as_cast(test_data, descriptor, opts)
  
  def cast_map(test_data, descriptor, opts \\ []),
    do: Get.cast_map(test_data, descriptor, opts)
end
