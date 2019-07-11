defmodule Crit.Ecto.TrimmedStringTest do
  use ExUnit.Case, async: true

  alias Crit.Ecto.TrimmedString

  test "trims strings" do
    assert TrimmedString.cast(" internal blanks are not trimmed\t ") ==
      {:ok, "internal blanks are not trimmed"}
      
    assert TrimmedString.cast(1) == :error
  end

  test "loading and dumping are no-ops" do
    untrimmed = "  should have been trimmed before saving "
    assert TrimmedString.load(untrimmed) == {:ok, untrimmed}
    assert TrimmedString.dump(untrimmed) == {:ok, untrimmed}
  end
end
