defmodule Crit.Params.Validation do
  use Crit.TestConstants
  import ExUnit.Assertions
  alias Ecto.Changeset
  import Crit.Assertions.Changeset

  def data_source(), do: Process.get(:data_source)

  def empty_struct, do: struct(data_source().module_under_test())
  def all_names, do: Map.keys(data_source().data())
  def all_values, do: Map.values(data_source().data())
  def one_value(name), do: Map.fetch!(data_source().data(), name)
  def default_cast_fields(), do: data_source().default_cast_fields()
  def module_under_test(), do: data_source().module_under_test()
  
  def validate_categories(categories, function_runner, verbose) do 
    for name <- exemplar_names_for_categories(categories) do
      if verbose do 
        IO.puts "Exemplar `#{inspect name}` in partition #{inspect categories}:"
        IO.inspect(only(name))
      end
      validate(name, function_runner)
    end
  end
  
  defp validate(exemplar_name, function_runner) when is_atom(exemplar_name) do
    case that_are(exemplar_name) |> function_runner.() do
      %Ecto.Changeset{} = changeset ->
        run_assertions(changeset, exemplar_name)
      [] -> 
        :no_op
      x ->
        IO.puts "Expected either a changeset or emptiness, not:"
        IO.inspect x
        flunk "Most likely, #{inspect function_runner} should end with []"
    end
  end
  
  def exemplar_names_for_category(category) when is_atom(category),
    do: filter_by_categories(all_names(), [category])
  
  def exemplar_names_for_categories(categories) when is_list(categories),
    do: filter_by_categories(all_names(), categories)
  
  def exemplars(categories) when is_list(categories) do
    all_values()
    |> filter_by_categories(categories)
    |> Enum.map(&(&1.params))
  end
  
  defp filter_by_categories(names, [category | remainder]) do
    names
    |> Enum.filter(&Enum.member?(one_value(&1).categories, category))
    |> filter_by_categories(remainder)
  end
  
  defp filter_by_categories(names, []), do: names
  
  def run_assertions(changeset, descriptor) do
    item = one_value(descriptor)
    
    assert changeset.valid? == Enum.member?(item.categories, :valid)
    
    unchanged_fields = Map.get(item, :unchanged, [])
    assert_change(changeset, as_cast(descriptor, without: unchanged_fields))
    assert_unchanged(changeset, unchanged_fields)
  end
  
  def only([descriptor | opts]) do
    only(descriptor)
    |> Map.merge(exceptions(opts))
    |> Map.drop(deleted_keys(opts))
  end
  
  def only(descriptor), do: one_value(descriptor).params
  
  defp exceptions(opts), do: Keyword.get(opts, :except, %{})
  defp without(opts), do: Keyword.get(opts, :without, [])
  defp deleted_keys(opts), do: Keyword.get(opts, :deleting, [])
  
  defp fields_to_check(descriptor, opts) do
    pure_fields = Map.get(one_value(descriptor), :to_cast, default_cast_fields())
    extras = exceptions(opts) |> Map.keys
    
    pure_fields
    |> Enum.concat(extras)
    |> ListX.delete(without(opts))
  end
  
  def as_cast(descriptor, opts \\ []) do
    cast_value = 
      empty_struct()
      |> Changeset.cast(only(descriptor), module_under_test().fields())
      |> Changeset.apply_changes
      |> Map.merge(exceptions(opts))
      |> Map.drop(without(opts))
    
    for field <- fields_to_check(descriptor, opts), 
      do: {field, Map.get(cast_value, field)}
  end
  
  def that_are(descriptors) when is_list(descriptors) do
    descriptors
    |> Enum.map(&only/1)
    |> exemplars_to_params
  end
  
  def that_are(descriptor), do: that_are([descriptor])
  
  def that_are(descriptor, opts), do: that_are([[descriptor | opts]])
  
  
  def exemplars_to_params(exemplars) do
    exemplars
    |> Enum.with_index
    |> Enum.map(fn {entry, index} ->
      key = to_string(index)
      value = Map.put(entry, "index", to_string(index))
      {key, value}
    end)
    |> Map.new
    
  end
end

