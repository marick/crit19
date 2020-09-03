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

  
  describe "loading completely" do
    @fake_animal %{id: "bossie_id", bossie_association: :unloaded}    

    defp loader_maker(schema) do 
      assert schema == :animal
      fn value ->
        assert value == @fake_animal
        %{@fake_animal | bossie_association: %{id: "loaded"}}
      end
    end

    setup do
      [repo: B.Schema.put(@start, :animal, "bossie", @fake_animal)]
    end

    test "a list of schemas", %{repo: repo} do
      repo
      |> B.load_completely([:animal], &loader_maker/1)
      |> B.Schema.get(:animal, "bossie")
      |> assert_field(bossie_association: %{id: "loaded"})
    end

    test "a single schema", %{repo: repo} do
      repo
      |> B.load_completely(:animal, &loader_maker/1)
      |> B.Schema.get(:animal, "bossie")
      |> assert_field(bossie_association: %{id: "loaded"})
    end
    
  end
end
