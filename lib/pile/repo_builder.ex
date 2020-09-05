defmodule Pile.RepoBuilder do
  @moduledoc """
  Support code for the creation of builders that (1) create persistent state,
  typically in an Ecto Repo, and (2) produce a map that describes that
  persistent state in a form that's convenient for tests. That map is
  conventionally called the "repo". 
  
  The main part of the structure looks like this:

        %{__schemas__: 
           %{animal: %{"bossie" => %Animal{name: "bossie", ...},
                       "daisy" => %Animal{name: "daisy", ...}},
             procedure: ...
            },
         ...}

  Individual animals can be gotten from the schema with `get/3`, but
  there's a shorthand notation that's usually better. You can choose for
  the repo to have top-level keys that are the names of leaf values:
  
        %{__schemas__:
           %{animal: %{"bossie" => %Animal{name: "bossie", ...}...}...},
          bossie: %Animal{name: "bossie",...}, 
          ...
         }

  That means one variable gives convenient access to everything
  that's on disk at the start of the test. Most especially, it makes it
  easy to get at ids:
  
        |> VM.Animal.lower_changeset(repo.bossie.id, @institution)
                                     ^^^^^^^^^^^^^^
        |> assert_change(span: Datespan.inclusive_up(repo.bossie.span.first))
                                                     ^^^^^^^^^^^^^^^^^^^^^^
  """
  
  defmodule Schema do
    import DeepMerge

    @moduledoc """
    Functions for working with schemas inside a repo.
    """
    
    @doc """
    Put a value into a repo structure.

         put(repo, :animal, "bossie", %Animal{...})

    If the first key (`:animal`) is missing, it is created.

    If the second key (`"bossie"`) is already present, it is overwritten.

    See also `create_if_needed/4`
    """
    
    def put(repo, schema, name, value) do
      deep_merge(repo, %{__schemas__: %{schema => %{name => value}}})
    end

    @doc """
    Replace some schema values within the repo.

    The final argument is an enumeration of `{name, value}` pairs.
    All of the values are installed, as with `put/4`, under the corresponding
    name. 
    """
    def replace(repo, schema, pairs) do
      deep_merge(repo, %{__schemas__: %{schema => Map.new(pairs)}})
    end

    @doc """
    Get a value from a repo structure.

        repo
        |> get(:animals, "bossie")

    The first key typically represents a Schema (it may in fact be the
    schema's name), the second an individual instance of the schema.

    Return `nil` if either key does not exist.
    """
    def get(repo, schema, name) do
      schemas(repo)[schema][name]
    end

    @doc """
    Like `put/4`, but does nothing if the value already exists.

    This supports the creation of functions used as shown:

        empty_repo()
        |> procedure("haltering", frequency: "twice per week")
        |> reservation_for(["bossie"], ["haltering"], date: @mon)

    `reservation_for` is written so that it calls these two functions for
    the above data:

        animal("bossie")
        procedure("haltering")

    Those in turn call `create_if_needed`. In the case of "bossie", an
    animal is created. Nothing is guaranteed about that animal but
    that it exists and has the name bossie.

    In the case of "haltering", nothing is done because the procedure
    already exists. 
    """
    def create_if_needed(repo, schema, name, creator) do 
      case get(repo, schema, name) do
        nil -> put(repo, schema, name, creator.())
        _ -> repo
      end
    end

    @doc """
    Return all the names (keys) for the given schema.

    Returns [] if the schema does not exist.
    """
    def names(repo, schema) do
      Map.get(schemas(repo), schema, %{}) |> Map.keys
    end

    defp schemas(repo), do: Map.get(repo, :__schemas__, %{})
  end

  @doc """
  Reload all values in a list of schemas, with thoroughness determined by caller.

      reload(repo, [:animal, :procedure], reloader)

  The result is a new repo, with the values within the schemas having
  been reloaded from the persistent store.

  The `reloader` takes two arguments: the schema and a list of current
  values. It could be a function like this:

     defp reload_some(:animal, animals),
       do: Enum.map(animals, &(&1.id)) |> Animal.get_by_ids
       
     defp reload_some(:procedures, procedures),
       do: Enum.map(procedures, &(&1.id)) |> Procedure.get_by_ids

  There are these variants:

      reload(repo, schemas: [:animal, :procedure]        )
      reload(repo, schema:   :animal                     )
      reload(repo, schema:   :animal,  names: ["bossie"] )
      reload(repo, schema:   :animal,  name:   "bossie"  )

  It is safe - a no-op - to refer to a schema that has never been created (and
  consequently contains no values. Referring to a nonexistent name raises an
  exception.
  
  """
  def reload(repo, reloader, opts) do
    case Enum.into(opts, %{}) do
      %{schema: schema, names: names} ->
        reload_for_names_within_schema(repo, schema, names, reloader)
      %{schema: schema, name: name} ->
        reload_for_names_within_schema(repo, schema, [name], reloader)
      %{schema: schema} ->
        reload_for_all_within_schema(repo, schema, reloader)
      %{schemas: schemas} ->
        reload_for_all_within_schemas(repo, schemas, reloader)
    end
  end

  defp reload_for_all_within_schemas(repo, schema_list, reloader) do
    Enum.reduce(schema_list, repo, fn schema, acc ->
      reload_for_all_within_schema(acc, schema, reloader)
    end)
  end

  defp reload_for_all_within_schema(repo, schema, reloader) do
    names = Schema.names(repo, schema)
    reload_for_names_within_schema(repo, schema, names, reloader)
  end

  IO.puts "Note that order must be guaranteed."
  defp reload_for_names_within_schema(repo, schema, names, reloader) do
    values =
      for n <- names, do: requiring_existence(repo, schema, n, &(&1))
    new_values = reloader.(schema, values)
    replacements = Enum.zip(names, new_values)

    Schema.replace(repo, schema, replacements)
  end
  

  @doc """
  Make particular names available in a `repo.name` format.

  This:

       repo = 
         put(:animal, "bossie", %Animal{id: 5})
         shorthand(schema: :animal)

  allows this:

       repo.bossie.id    # 5

  There are these variants:

      shorthand(repo, schemas: [:animal, :procedure]        )
      shorthand(repo, schema:   :animal                     )
      shorthand(repo, schema:   :animal,  names: ["bossie"] )
      shorthand(repo, schema:   :animal,  name:   "bossie"  )

  It is safe - a no-op - to refer to a schema that has never been created (and
  consequently contains no values. Referring to a nonexistent name raises an
  exception.
  """
  def shorthand(repo, opts) do
    case Enum.into(opts, %{}) do
      %{schema: schema, names: names} -> 
        shorthand_for_names_within_schema(repo, schema, names)
      %{schema: schema, name: name} ->
        shorthand_for_names_within_schema(repo, schema, [name])
      %{schema: schema} ->
        shorthand_for_all_within_schema(repo, schema)
      %{schemas: schemas} ->
        shorthand_for_all_within_schemas(repo, schemas)
    end
  end

  defp shorthand_for_all_within_schemas(repo, schema_list) do
    Enum.reduce(schema_list, repo, fn schema, acc ->
      shorthand_for_all_within_schema(acc, schema)
    end)
  end

  defp shorthand_for_all_within_schema(repo, schema) do
    names = Schema.names(repo, schema)
    shorthand_for_names_within_schema(repo, schema, names)
  end


  defp shorthand_for_names_within_schema(repo, schema, names) do
    Enum.reduce(names, repo, fn name, acc ->
      requiring_existence(repo, schema, name, fn value ->
        name_atom = name |> String.downcase |> String.to_atom
        Map.put(acc, name_atom, value)
      end)
    end)
  end


  defp requiring_existence(repo, schema, name, f) do
    case Schema.get(repo, schema, name) do
      nil ->
        raise "There is no `#{inspect name}` in schema `#{inspect schema}`"
      value ->
        f.(value)
    end
  end


  defmacro __using__(_) do
    quote do 
      alias Pile.RepoBuilder, as: B
      
      def get(repo, schema, name),
        do: B.Schema.get(repo, schema, name)
        def shorthand(repo, opts),
          do: B.Schema.shorthand(repo, opts)
    end
  end
end
