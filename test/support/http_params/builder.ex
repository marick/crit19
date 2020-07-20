defmodule Crit.Params.Builder do

  # convert shorthand into the kind of parameters delivered to
  # controller actions.
  
  def to_strings(map) when is_map(map) do
    map
    |> Enum.map(fn {k,v} -> {to_string(k), to_string_value(v)} end)
    |> Map.new
  end

  defp to_string_value(value) when is_list(value), do: Enum.map(value, &to_string/1)
  defp to_string_value(value) when is_map(value), do: to_strings(value)
  defp to_string_value(value), do: to_string(value)

  defmacro __using__(
    view_module: view_module,
    default_cast_fields: default_cast_fields,
    data: data
  ) do 
    quote do
      use Crit.TestConstants
      import ExUnit.Assertions
      alias Ecto.Changeset
      import Crit.Params.Builder
      import Crit.Assertions.Changeset
      alias Crit.Params.Validation
      
      def data(), do: unquote(data)
      def default_cast_fields, do: unquote(default_cast_fields)
      def view_module, do: unquote(view_module)

      def validate_categories(categories, function_runner, verbose \\ false) do 
        Process.put(:data_source, __MODULE__)
        Validation.validate_categories(categories, function_runner, verbose)
      end

      def validate_category(category, function_runner, verbose \\ false) do 
        Process.put(:data_source, __MODULE__)
        validate_categories([category], function_runner, verbose)
      end

      def as_cast(descriptor, opts \\ []) do
        Process.put(:data_source, __MODULE__)
        Validation.as_cast(descriptor, opts)
      end

      def accept_form(descriptor) do
        Process.put(:data_source, __MODULE__)
        Validation.that_are(descriptor) |> view_module().accept_form
      end
      
      def lower_changesets(descriptor) do
        Process.put(:data_source, __MODULE__)
        {:ok, vm_changesets} = accept_form(descriptor)
        view_module().lower_changesets(vm_changesets)
      end


      def that_are(descriptors) when is_list(descriptors) do
        Process.put(:data_source, __MODULE__)
        descriptors
        |> Enum.map(&Validation.only/1)
        |> Validation.exemplars_to_params
      end
  
      def that_are(descriptor) do 
        Process.put(:data_source, __MODULE__)
        Validation.that_are([descriptor])
      end
        
      def that_are(descriptor, opts) do
        Process.put(:data_source, __MODULE__)
        Validation.that_are([[descriptor | opts]])
      end
    end
  end  
end
