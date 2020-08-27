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
end
