defmodule SpikesTest do
  use ExUnit.Case
  doctest Spikes

  test "greets the world" do
    assert Spikes.hello() == :world
  end
end
