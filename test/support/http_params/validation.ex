defmodule Crit.Params.Validation do
  use Crit.TestConstants
  import ExUnit.Assertions
  alias Ecto.Changeset
  import Crit.Assertions.Changeset
  alias Crit.Params.Builder

  # ----------------------------------------------------------------------------

  def as_cast(descriptor, opts \\ []) do
    opts = Enum.into(opts, %{except: %{}, without: []})
    cast_value = 
      empty_struct()
      |> Changeset.cast(Builder.only(descriptor), module_under_test().fields())
      |> Changeset.apply_changes
      |> Map.merge(opts.except)
      |> Map.drop(opts.without)
    
    for field <- fields_to_check(descriptor, opts.except, opts.without), 
      do: {field, Map.get(cast_value, field)}
  end

  defp fields_to_check(descriptor, except, without) do
    one_value(descriptor)
    |> Map.get(:to_cast, default_cast_fields())
    |> Enum.concat(Map.keys(except))
    |> ListX.delete(without)
  end
  
  
  # ----------------------------------------------------------------------------

  def check_actual(actual, exemplar_name) do
    case actual do
      %Ecto.Changeset{} = changeset ->
        run_assertions(changeset, exemplar_name)
      [] -> 
        :no_op
      x ->
        IO.puts "Expected either a changeset or emptiness, not:"
        IO.inspect x
        flunk "Most likely, the function given should end with []"
    end
  end

  # ----------------------------------------------------------------------------

  defp data_source(), do: Process.get(:data_source)

  defp empty_struct, do: struct(data_source().module_under_test())
  defp one_value(name), do: Map.fetch!(data_source().data(), name)
  defp default_cast_fields(), do: data_source().default_cast_fields()
  defp module_under_test(), do: data_source().module_under_test()


  def note_name(name, verbose) do
    if verbose, do: IO.puts("+ #{inspect name}")
  end
  
  def filter_by_categories(names, categories, verbose) do
    if verbose, do: IO.puts(">> Partition #{inspect categories}")
    filter_by_categories(names, categories)
  end

  def filter_by_categories(names, [category | remainder]) do
    names
    |> Enum.filter(&Enum.member?(one_value(&1).categories, category))
    |> filter_by_categories(remainder)
  end
  
  def filter_by_categories(names, []), do: names
  
  defp run_assertions(changeset, descriptor) do
    item = one_value(descriptor)
    
    assert changeset.valid? == Enum.member?(item.categories, :valid)
    
    unchanged_fields = Map.get(item, :unchanged, [])
    assert_change(changeset, as_cast(descriptor, without: unchanged_fields))
    assert_unchanged(changeset, unchanged_fields)
  end
end

