defmodule Pile.RepoBuilder do

  defmodule Schema do
    import DeepMerge
    
    def put(so_far, schema, name, value) do
      deep_merge(so_far, %{__schemas__: %{schema => %{name => value}}})
    end

    def get(so_far, schema, name) do
      so_far[:__schemas__][schema][name]
    end

    def create_if_needed(so_far, schema, name, creator) do 
      case get(so_far, schema, name) do
        nil -> put(so_far, schema, name, creator.())
        _ -> so_far
      end
    end
  end
end
