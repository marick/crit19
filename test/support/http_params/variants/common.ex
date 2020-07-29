defmodule Crit.Params.Variants.Common do

  defmacro __using__(_) do
    quote do
      use Crit.Errors
      use Crit.TestConstants
      import ExUnit.Assertions
      import Crit.Assertions.Defchain
      import Crit.Params.Build, only: [to_strings: 1, build: 1, like: 2]
      alias Crit.Params.{Get,Validate}
      import Crit.Assertions.{Ecto,Map}

      def config(), do: __MODULE__.test_data()
      def config(:all_names), do: Map.keys(config(:exemplars))
      def config(atom), do: config()[atom]

      def as_cast(descriptor, opts \\ []),
        do: Get.as_cast(config(), descriptor, opts)

      def cast_map(descriptor, opts \\ []),
        do: Get.cast_map(config(), descriptor, opts)


      def check_form_validation(opts) do
        opts = Enum.into(opts, %{verbose: false})

        check =
          case Map.get(opts, :result) do
            nil ->
              fn result, name -> check_changeset(result, name) end
            f -> f
          end

        names = 
          Get.names_in_categories(config(), opts.categories, opts.verbose)
        
        for name <- names do
          Validate.note_name(name, opts.verbose)
          accept_form(name) |> check.(name)
        end
      end
      
      defchain validate(:lowered, name),
        do: Validate.Lowering.check(config(), name, lower_changesets(name))

      defchain validate(:form_checking, name, changeset) do 
        Validate.FormChecking.check(config(), changeset, name)
      end
    end
  end
end
  
