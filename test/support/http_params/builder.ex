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


  def build(keywords) do
    start = Enum.into(keywords, %{})

    expanded_exemplars =
      Enum.reduce(start.exemplars, %{}, &add_real_exemplar/2)

    Map.put(start, :data, expanded_exemplars)
  end


  defp add_real_exemplar({new_name, %{params: params} = raw_data}, acc) do
    expanded_params =
      case params do
        {:__like, earlier_name, overriding_params} ->
          Map.merge(acc[earlier_name].params, overriding_params)
        _ ->
          params
      end
    expanded_data = Map.put(raw_data, :params, expanded_params)
    Map.put(acc, new_name, expanded_data)
  end


  def like(valid, except: map) do 
    {:__like, valid, to_strings(map)}
  end

  # ----------------------------------------------------------------------------

  def one_value(config, name), do: config.data[name]
  
  defp exceptions(opts), do: Keyword.get(opts, :except, %{})
  defp deleted_keys(opts), do: Keyword.get(opts, :deleting, [])

  def make_numbered_params(config, descriptors) when is_list(descriptors) do
    descriptors
    |> Enum.map(&(only(config, &1)))
    |> combine_into_numbered_params
  end

  defp combine_into_numbered_params(exemplars) do
    exemplars
    |> Enum.with_index
    |> Enum.map(fn {entry, index} ->
      key = to_string(index)
      value = Map.put(entry, "index", to_string(index))
      {key, value}
    end)
    |> Map.new  
  end

  def only(config, [descriptor | opts]) do
    only(config, descriptor)
    |> Map.merge(exceptions(opts))
    |> Map.drop(deleted_keys(opts))
  end
  
  def only(config, descriptor), do: one_value(config, descriptor).params

  # ----------------------------------------------------------------------------

  defmacro __using__(_) do
    quote do
      use Crit.Errors
      use Crit.TestConstants
      import ExUnit.Assertions
      import Crit.Params.Builder, only: [to_strings: 1, build: 1, like: 2]
      alias Crit.Params.Builder
      alias Crit.Params.Validation
      import Crit.Assertions.{Ecto,Map}

      def config(), do: __MODULE__.test_data()
      def config(:all_names), do: Map.keys(config(:data))
      def config(atom), do: config()[atom]

      def validate_changeset(name, changeset),
        do: Validation.validate_changeset(config(), changeset, name)

      def as_cast(descriptor, opts \\ []) do
        Validation.as_cast(config(), descriptor, opts)
      end

      def validate_categories(categories, function_runner, verbose \\ false) do
        exemplar_names =
          Validation.filter_by_categories(config(), categories, verbose)

        for name <- exemplar_names do 
          Validation.note_name(name, verbose)

          Validation.check_actual(
            config(),
            (make_params_for_name(config(), name) |> function_runner.()),
            name)
        end
      end

      # Convenience
      def validate_category(category, function_runner, verbose \\ false) do 
        validate_categories([category], function_runner, verbose)
      end


      def validate_lowered_values(descriptor) do
        config = config()
        exemplar = Builder.one_value(config, descriptor)
        [{field_to_split, destination_field}] = Enum.into(config.lowering_splits, [])
        actuals = lower_changesets(descriptor)

        split_cast_values = Keyword.get(as_cast(descriptor), field_to_split)
        
        for struct <- actuals do
          cast_map = Enum.into(as_cast(descriptor), %{})
          
          struct
          |> assert_schema(config.produces)
          |> assert_partial_copy(cast_map, config.lowering_retains)
        end

        for {struct, split_value} <- Enum.zip(actuals, split_cast_values) do
          assert Map.get(struct, destination_field) == split_value
        end
      end        
    end
  end
end
