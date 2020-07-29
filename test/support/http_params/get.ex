defmodule Crit.Params.Get do
  alias Ecto.Changeset
  
  def exemplar(config, name), do: config.exemplars[name]

  def params(config, [descriptor | opts]) do
    opts = terser(opts, except: %{}, deleting: [])
    params(config, descriptor)
    |> Map.merge(opts.except)
    |> Map.drop(opts.deleting)
  end
  
  def params(config, name), do: exemplar(config, name).params

  @doc """
   Produces a map from index to exemplar params. That's the way
   arrays of checkboxes are normally sent. So you'll get something
   like this:

        %{
         "0" => %{
           "frequency_id" => "1",
           "name" => "one"
         },
         "1" => %{
           "frequency_id" => "1",
           "name" => "two",
           "species_ids" => ["1"]
         }, ...
  """
  def numbered_params(config, descriptors) do
    one_map_entry = fn {exemplar_params, index} ->
      key = to_string(index)
      value = Map.put(exemplar_params, "index", to_string(index))
      {key, value}
    end
    
    descriptors
    |> Enum.map(&(params(config, &1)))
    |> Enum.with_index
    |> Enum.map(one_map_entry)
    |> Map.new  
  end

  @doc """
   As above, but adds an `index_field` with the appropriate
   index value, like so:

        %{
         "0" => %{
           "frequency_id" => "1",
           "index" => "0",              ## <<<---
           "name" => ""
         },
         "1" => %{
           "frequency_id" => "1",
           "index" => "1",              ## <<<---
           "name" => "",
           "species_ids" => ["1"]
         }, ...
  """
  def doubly_numbered_params(config, descriptors, index_field) do
    add_index_to_each_exemplar = fn {index, exemplar_params} ->
      {index, Map.put(exemplar_params, index_field, index)}
    end
    
    numbered_params(config, descriptors)
    |> Enum.map(add_index_to_each_exemplar)
    |> Map.new
  end

  def cast_map(config, descriptor, opts \\ []) do
    opts = terser(opts, except: %{}, without: [])
    fields = config.module_under_test.fields()

    struct(config.module_under_test)
    |> Changeset.cast(params(config, descriptor), fields)
    |> Changeset.apply_changes
    |> Map.merge(opts.except)
    |> Map.drop(opts.without)
  end

  def as_cast(config, descriptor, opts \\ []) do
    opts = terser(opts, except: %{}, without: [])
    map = cast_map(config, descriptor, opts)
    
    for field <- field_names(config, opts.except, opts.without), 
      do: {field, Map.get(map, field)}
  end

  defp field_names(config, except, without) do
    config.validates
    |> Enum.concat(Map.keys(except))
    |> ListX.delete(without)
  end

  def names_in_categories(config, categories, verbose) do
    if verbose, do: IO.puts("\n>> Partition #{inspect categories}")
    all_names = Map.keys(config.exemplars)
    filter_by_categories(config, all_names, categories)
  end

  defp filter_by_categories(config, names, categories) do
    Enum.reduce(categories, names, fn category, acc ->
      Enum.filter(acc, &Enum.member?(exemplar(config, &1).categories, category))
    end)
  end

  # ----------------------------------------------------------------------------
  defp terser(opts, defaults) do
    defaults = Enum.into(defaults, %{})
    Enum.into(opts, defaults)
  end    
end
