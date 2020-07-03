defmodule Crit.Setup.AnimalImpl.ReadTest do
  use Crit.DataCase
  alias Crit.Setup.AnimalImpl.Read
  
  describe "bulk queries order by name" do
    test "... not by id order when fetching by ids" do 
      %{id: id1} = Factory.sql_insert!(:animal, [name: "ZZZ"], @institution)
      %{id: id3} = Factory.sql_insert!(:animal, [name: "m"], @institution)
      %{id: id2} = Factory.sql_insert!(:animal, [name: "aaaaa"], @institution)

      ordering = 
        Read.ids_to_animals([id1, id2, id3], @institution)
        |> EnumX.names

      assert ordering == ["aaaaa", "m", "ZZZ"]
    end

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


  test "when fetching ids, missing ids are silently ignored" do
    %{id: id} = Factory.sql_insert!(:animal, @institution)

    [%{id: ^id}] = Read.ids_to_animals([id * 2000, id * 4000, id], @institution)
  end
end
