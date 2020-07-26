defmodule Crit.Params.ManyToManyBuilder do
  @moduledoc """
  A builder for controller params of this form:

  %{
    "0" => %{...},
    "1" => %{...},
    ...
  }
  """

  defmacro __using__(_) do
    quote do
      use Crit.Params.Builder
      alias Crit.Params.Builder
      alias Crit.Params.Validation

      # ----------------------------------------------------------------------------

      defp make_params_for_name(config, name),
        do: Builder.make_numbered_params(config(), [name])


      def that_are(descriptors) when is_list(descriptors) do
        Builder.make_numbered_params(config(), descriptors)
      end
  
      def that_are(descriptor),       do: that_are([descriptor])
      def that_are(descriptor, opts), do: that_are([[descriptor | opts]])

      # ----------------------------------------------------------------------------

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
