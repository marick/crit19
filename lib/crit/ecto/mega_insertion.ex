defmodule Ecto.MegaInsertion do
  defmodule Base do
    alias Crit.Sql
    alias Ecto.Multi
    
    def tx_key(keys, index), do: {keys.struct, index}
    def is_tx_key?(keys, {key, _count}), do: keys.struct == key
    def is_tx_key?(_, _), do: false


    def reduce_to_idlist(keys, tx_result) do
      reducer = fn {key, value}, acc ->
        case is_tx_key?(keys, key) do
          true ->
            [value.id | acc]
          false ->
            acc
        end
      end
      
      result = 
        tx_result
        |> Enum.reduce([], reducer)
        |> Enum.reverse
      
      {:ok, result}
    end

    def multi_insert(keys, changesets, institution) do
      add_insertion = fn {changeset, index}, acc ->
        Multi.insert(acc, tx_key(keys, index), changeset, Sql.multi_opts(institution))
      end
      
      changesets
      |> Enum.with_index
      |> Enum.reduce(Multi.new, add_insertion)
    end

    def multi_collecting_ids(keys, changesets, institution) do 
      multi_insert(keys, changesets, institution)
      |> Multi.run(keys.ids,
        fn _repo, result -> reduce_to_idlist(keys, result)
      end)
    end

    def resulting_ids(keys, transaction_result) do
      Map.fetch!(transaction_result, keys.ids)
    end
  end

  
  defmacro __using__(key) do 

    append = fn atom, suffix ->
      "#{Atom.to_string(atom)}#{suffix}" |> String.to_atom
    end

    keys = %{struct: key,
             structs: append.(key, "s"),
             ids: append.(key, "_ids")
            }
    
    quote do
      alias Ecto.Multi
      alias Crit.Sql
      alias Ecto.MegaInsertion.Base
      @keys unquote(Macro.escape(keys))

      def reduce_to_idlist(_repo, tx_result),
        do: Base.reduce_to_idlist(@keys, tx_result)

      def multi_insert(changesets, institution),
        do: Base.multi_insert(@keys, changesets, institution)

      def multi_collecting_ids(changesets, institution),
       do: Base.multi_collecting_ids(@keys, changesets, institution)

      def resulting_ids({:ok, transaction_result}),
        do: Base.resulting_ids(@keys, transaction_result)

      # These are really for testing. 
      
      def run(changesets_or_structs, institution) do
        changesets_or_structs
        |> multi_insert(institution)
        |> Sql.transaction(institution)
      end

      def run_for_ids(changesets_or_structs, institution) do
        changesets_or_structs
        |> multi_collecting_ids(institution)
        |> Sql.transaction(institution)
        |> resulting_ids
      end
    end
  end
end
