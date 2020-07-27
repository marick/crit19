defmodule Crit.Params.Validation do
  use Crit.TestConstants
  import ExUnit.Assertions
  alias Ecto.Changeset
  import Crit.Assertions.Changeset
  alias Crit.Params.Builder
  import Crit.Assertions.{Ecto,Map}
  alias Pile.Namelist

  # ----------------------------------------------------------------------------
  def as_cast(config, descriptor, opts \\ []) do
    opts = Enum.into(opts, %{except: %{}, without: []})
    cast_value =
      struct(config.module_under_test)
      |> Changeset.cast(Builder.only(config, descriptor), config.module_under_test.fields())
      |> Changeset.apply_changes
      |> Map.merge(opts.except)
      |> Map.drop(opts.without)
    
    for field <- fields_to_check(config, descriptor, opts.except, opts.without), 
      do: {field, Map.get(cast_value, field)}
  end

  defp fields_to_check(config, descriptor, except, without) do
    one_value(config, descriptor)
    |> Map.get(:to_cast, config.validates)
    |> Enum.concat(Map.keys(except))
    |> ListX.delete(without)
  end
  
  
  # ----------------------------------------------------------------------------

  def check_actual(config, actual, exemplar_name) do
    case actual do
      %Ecto.Changeset{} = changeset ->
        validate_changeset(config, changeset, exemplar_name)
      [] -> 
        :no_op
      x ->
        IO.puts "Expected either a changeset or emptiness, not:"
        IO.inspect x
        flunk "Most likely, the function given should end with []"
    end
  end

  # ----------------------------------------------------------------------------

  defp one_value(config, name), do: Map.fetch!(config.data, name)

  def note_name(name, verbose) do
    if verbose, do: IO.puts("+ #{inspect name}")
  end

  def filter_by_categories(config, names, [category | remainder]) do
    filtered = 
      Enum.filter(names, &Enum.member?(one_value(config, &1).categories, category))
    filter_by_categories(config, filtered, remainder)
  end
  
  def filter_by_categories(_config, names, []), do: names

  def filter_by_categories(config, categories, verbose) do
    if verbose, do: IO.puts(">> Partition #{inspect categories}")
    all_names = Map.keys(config.data)
    filter_by_categories(config, all_names, categories)
  end


  
  def validate_changeset(config, changeset, descriptor) do
    item = one_value(config, descriptor)
    if Map.has_key?(item, :verbose) do
      IO.inspect(item.params, label: to_string(descriptor))
      IO.inspect(changeset, label: "changeset")
      IO.inspect(changeset.data, label: "underlying data")
    end
    
    assert changeset.valid? == Enum.member?(item.categories, :valid)
    
    unchanged_fields = Map.get(item, :unchanged, [])
    errors = Map.get(item, :errors, [])

    changeset
    |> assert_change(as_cast(config, descriptor, without: unchanged_fields))
    |> assert_unchanged(unchanged_fields)
    |> assert_errors(errors)
  end

  def assert_lowered(config, descriptor, actuals) do
    assert_non_split_values(config, descriptor, actuals)
    assert_split_value(config, descriptor, actuals)
  end

  defp assert_non_split_values(config, descriptor, actuals) do 
    for struct <- actuals do
      cast_map = Enum.into(as_cast(config, descriptor), %{})
      
      struct
      |> assert_schema(config.produces)
      |> assert_partial_copy(cast_map, config.lowering_retains)
    end
  end

  defp assert_split_value(config, descriptor, actuals) do
    [{field_to_split, destination_field}] = Enum.into(config.lowering_splits, [])
    split_cast_values = split(as_cast(config, descriptor), field_to_split)

    for {struct, split_value} <- Enum.zip(actuals, split_cast_values),
      do: assert Map.get(struct, destination_field) == split_value
  end

  
  defp split(cast_values, field_to_split),
    do: Keyword.get(cast_values, field_to_split) |> split_value

  defp split_value(value) when is_list(value), do: value
  defp split_value(value) when is_binary(value), do: Namelist.to_list(value)
end

