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
    Get a value from a repo structure.

        repo
        |> get(:animals, "bossie")

    The first key typically represents a Schema (it may in fact be the
    schema's name), the second an individual instance of the schema.

    Return `nil` if either key does not exist.
    """
    def get(repo, schema, name) do
      repo[:__schemas__][schema][name]
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

    Raises an error if the schema does not exist.
    """
    def names(repo, schema) do
      Map.get(repo[:__schemas__], schema) |> Map.keys
    end
  end

  @doc """
  Reload all values in a list of schemas, typically preloading all associations.

      load_completely(repo, [:animal, :procedure], fetch_loader)

  The result is a new repo, with the values within the schemas having
  been reloaded from the persistent store.

  `fetch_loader` is a function that takes a schema (typically an atom)
  and returns a function. That function takes a current value and
  returns a new one. When working with Ecto, the function is typically
  something like this:

      fn old -> Repo.get(Animal, old.id, preload: [:species, :service_gaps])

  If there's only a single schema, you don't have to put it into a list.
  
  """
  def load_completely(repo, schemas, fetch_loader) when is_list(schemas) do
    Enum.reduce(schemas, repo, fn schema, acc ->
      load_completely(acc, schema, fetch_loader)
    end)
  end

  def load_completely(repo, schema, fetch_loader) do
    names = Schema.names(repo, schema)
    load_some_names_completely(repo, schema, names, fetch_loader.(schema))
  end

  
  @doc """
  Reload some values from a schema, typically preloading all associations.

      repo
      |> load_some_names_completely(:animal, ["bossie"], loader)

  The result is a new repo, with the values identified by the names having
  been reloaded from the persistent store.

  `loader` is a function that takes a value (like the `Animal`
  associated with `"bossie"` and produces a new value. It's typically
  a function like this:

      fn old -> Repo.get(Animal, old.id, preload: [:species, :service_gaps])

  Note: this does not change values made available by `shorthand`. Generally,
  this function should only be used after `shorthand`. 

        repo
        |> service_gap_for("Bossie", name: "sg", starting: @earliest_date)
        |> load_completely(loader)
        |> shorthand

  """
  def load_some_names_completely(repo, schema, names, loader) do
    Enum.reduce(names, repo, fn name, acc ->
      old = Schema.get(acc, schema, name)
      Schema.put(acc, schema, name, loader.(old))
    end)
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

  """
  def shorthand(repo, opts) do
    case Enum.into(opts, %{}) do
      %{schemas: schemas} ->
        shorthand_for_all_within_schemas(repo, schemas)
      %{schema: schema, names: names} -> 
        shorthand_for_names_within_schema(repo, schema, names)
      %{schema: schema, name: name} ->
        shorthand_for_names_within_schema(repo, schema, [name])
      %{schema: schema} ->
        shorthand_for_all_within_schema(repo, schema)
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
      name_atom = name |> String.downcase |> String.to_atom
      value = Schema.get(repo, schema, name)
      Map.put(acc, name_atom, value)
    end)
  end
end
