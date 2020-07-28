defmodule Crit.Params.Get do
  def exemplar(config, name), do: config.exemplars[name]

  def params(config, [descriptor | opts]) do
    params(config, descriptor)
    |> Map.merge(exceptions(opts))
    |> Map.drop(deleted_keys(opts))
  end
  
  def params(config, descriptor), do: exemplar(config, descriptor).params

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

  # ----------------------------------------------------------------------------
  defp exceptions(opts), do: Keyword.get(opts, :except, %{})
  defp deleted_keys(opts), do: Keyword.get(opts, :deleting, [])
end
