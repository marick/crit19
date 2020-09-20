defmodule Crit.Params.Exemplar do
  alias Crit.Params.Get

  def as_cast(test_data, descriptor, opts \\ []),
    do: Get.as_cast(test_data, descriptor, opts)
  
  def cast_map(test_data, descriptor, opts \\ []),
    do: Get.cast_map(test_data, descriptor, opts)


  defmacro __using__(_) do
    alias Crit.Params.Exemplar
    
    quote do
      def as_cast(descriptor, opts \\ []),
        do: Exemplar.as_cast(test_data(), descriptor, opts)
      
      def cast_map(descriptor, opts \\ []),
        do: Exemplar.cast_map(test_data(), descriptor, opts)
    end
  end
end
