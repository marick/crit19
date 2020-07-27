defmodule Crit.Params.Variants.SingletonToMany do
  @moduledoc """
  A builder for controller params of this form:

  %{
    "0" => %{..., "split_field" => ...}},
    "1" => %{..., "split_field" => ...}},
    ...
  }

  A controller will typically receive N indexed parameters. For tests 
  using this module, only a single value is sent (with an index of "0").
  
  A further wrinkle is that the *split field* is used to produce separate copies
  of all the fields. For example, the split field might be a list of
  integers representing ids from a set of checkboxes. See `OneToMany` for more.
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
    end
  end  
end
