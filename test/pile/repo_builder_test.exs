defmodule Pile.RepoBuilderTest do
  use ExUnit.Case, async: true
  use FlowAssertions
  alias Pile.RepoBuilder, as: B

  @start %{}
  @sample ~D[2002-02-02]

  describe "get" do
    test "returns nil for a starting repo" do
      assert B.Schema.get(@start, Sample, "name") == nil
    end

    test "returns nil when schema hasn't been added" do
      @start
      |> B.Schema.put(:dates, "name", @sample)
      |> B.Schema.get(:some_other_schema, "name")
      |> assert_equal(nil)
    end

    test "typical returns" do
      repo = B.Schema.put(@start, :schema, "name", @sample)

      assert B.Schema.get(repo, :schema, "name") == @sample
      assert B.Schema.get(repo, :schema, "missing") == nil
    end
  end

  describe "creational code" do 
    test "put overwrites" do
      @start
      |> B.Schema.put(:dates, "name", "first value")
      |> B.Schema.put(:dates, "name", "second value")
      |> B.Schema.get(:dates, "name")
      |> assert_equal("second value")
    end
    
    test "create_if_needed does not overwrite" do
      repo =
        @start
        |> B.Schema.create_if_needed(:animal, "bossie", fn -> "bossie value" end)

      repo 
      |> B.Schema.get(:animal, "bossie")
      |> assert_equal("bossie value")
      
      repo
      |> B.Schema.create_if_needed(:animal, "bossie", fn -> "IGNORED" end)
      |> B.Schema.get(:animal, "bossie")
      |> assert_equal("bossie value")
    end
  end

  test "names" do
    repo = 
      B.Schema.put(@start, :animal, "bossie", "bossie content")

    assert B.Schema.names(repo, :animal) == ["bossie"]
    assert B.Schema.names(repo, :nothing) == []
  end    

  @fake_animal %{id: "bossie_id", association: :unloaded}    
  
  describe "loading completely" do

    defp reloader _schema, value do 
      %{value | association: %{note: "association loaded"}}
    end
      
    test "normal loading" do
      repo = B.Schema.put(@start, :animal, "bossie", @fake_animal)

      pass = fn opts ->
        repo
        |> B.reload(&reloader/2, opts)
        |> B.Schema.get(:animal, "bossie")
        |> assert_field(association: %{note: "association loaded"})
      end
      
      [schemas: [:animal]]                  |> pass.()
      [schema:   :animal ]                  |> pass.()
      [schema:   :animal, name: "bossie"  ] |> pass.()
      [schema:   :animal, names: ["bossie"] ] |> pass.()
    end

    test "the schema can be missing" do
      # It happens to create an empty one, which is harmless
      pass = fn opts, repo, schema ->
        new_repo = B.reload(repo, &reloader/2, opts)
        assert B.Schema.names(new_repo, schema) == []
      end

      # These are so empty they don't even have a __schemas__ key.
      [schemas: [:irrelevant]] |> pass.(@start, :irrelevant)
      [schema:   :irrelevant ] |> pass.(@start, :irrelevant)
      
      # This forces the __schemas__ key to be present.
      repo = B.Schema.put(@start, :animal, "bossie", "bossie")
      [schemas: [:missing_schema]] |> pass.(repo, :missing_schema)
      [schema:   :missing_schema ] |> pass.(repo, :missing_schema)
    end
    
    test "the name must exist in the schema" do
      repo = B.Schema.put(@start, :animal, "bossie", "bossie")

      assert_raise RuntimeError, fn -> 
        B.reload(repo, &reloader/2, schema: :animal, name: "missing")
      end
    end

    test "reloading re-establishes shorthand" do
      repo = 
        B.Schema.put(@start, :animal, "bossie", @fake_animal)
        |> B.shorthand(schema: :animal)
        |> B.reload(&reloader/2, schema: :animal)

      repo.bossie.association
      |> assert_field(note: "association loaded")
    end
  end

  describe "shorthand" do 
    test "fetching" do
      repo =
        @start
        |> B.Schema.put(:animal, "bossie", "bossie")
        |> B.Schema.put(:animal, "jake", "jake")
        |> B.Schema.put(:procedure, "haltering", "haltering")
      
      gives = fn opts, expected ->
        new_repo = B.shorthand(repo, opts)
        [Map.get(new_repo, :bossie), Map.get(new_repo, :jake)]
        |> Enum.reject(&(&1 == nil))
        |> assert_equal(expected)
      end
      
      [schemas: [:animal]                   ] |> gives.(["bossie", "jake"])
      [schema:   :animal                    ] |> gives.(["bossie", "jake"])
      [schema:   :animal, names: ["bossie"] ] |> gives.(["bossie"])
      [schema:   :animal, name:   "jake"    ] |> gives.(["jake"])
    end

    test "the schema can be missing" do
      pass = fn opts, repo ->
        assert B.shorthand(repo, opts) == repo
      end

      # These are so empty they don't even have a __schemas__ key.
      [schemas: [:irrelevant]] |> pass.(@start)
      [schema:   :irrelevant ] |> pass.(@start)
      
      # This forces the __schemas__ key to be present.
      repo = B.Schema.put(@start, :animal, "bossie", "bossie")
      [schemas: [:missing_schema]] |> pass.(repo)
      [schema:   :missing_schema ] |> pass.(repo)
    end

    test "the name must exist in the schema" do
      repo = B.Schema.put(@start, :animal, "bossie", "bossie")

      assert_raise RuntimeError, fn -> 
        B.shorthand(repo, schema: :animal, name: "missing")
      end
    end
  end
end
