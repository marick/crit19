defmodule Crit.Setup.AnimalImpl.ReadTest do
  use Crit.DataCase
  alias Crit.Setup.AnimalImpl.Read
  
  describe "bulk queries order by name" do
    test "when using `all`" do
      # This might not fail on a bug, since the animals could happen to be generated
      # in sorted order. But note that the names are different for each run of
      # the test.

      for name <- Factory.unique_names() do
        Factory.sql_insert!(:animal, [name: name], @institution)
      end

      as_read = Read.all(@institution) |> EnumX.names
      sorted = Enum.sort(as_read)

      assert as_read == sorted
    end
  end
end
