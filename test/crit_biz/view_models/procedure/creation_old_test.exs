defmodule CritBiz.ViewModels.Procedure.CreationTest do
  use Crit.DataCase
  alias CritBiz.ViewModels.Setup.BulkProcedure


  describe "checking form attributes" do
    test "both name and species id means validity" do 
      %BulkProcedure{}
      |> BulkProcedure.changeset(%{"name"=>"x", "species_ids" => ["0"]})
      |> assert_valid
    end
    
    test "both name and species missing also means validity" do 
      %BulkProcedure{}
      |> BulkProcedure.changeset(%{"name"=>""})
      |> assert_valid
    end
    
    test "if there's a name, there must be a species" do 
      %BulkProcedure{}
      |> BulkProcedure.changeset(%{"name"=>"procedure"})
      |> assert_invalid
      |> assert_error(species_ids: @at_least_one_species)
    end

    test "there can be a species without a name" do
      # ... so that a single button can select a species for N procedures"
      %BulkProcedure{}
      |> BulkProcedure.changeset(%{"species_ids" => ["1"]})
      |> assert_valid
    end
  end

  describe "changesetS return value" do
    test "on success" do
      input = [%{"name" => "prep",
                 "frequency_id" => "3",
                 "species_ids" => ["1"]}]
      assert {:ok, [only]} = BulkProcedure.changesets(input)
      only
      |> assert_valid
      |> assert_changes(name: "prep",
                        frequency_id: 3,
                        species_ids: [1])
    end
    
    test "on failure" do
      input = [%{"name" => "prep"}]
      assert {:error, [only]} = BulkProcedure.changesets(input)
      assert_invalid(only)
    end      
  end

  describe "unfolding changesets" do
    test "ones without names are ignored" do
      {:ok, changesets} = 
        BulkProcedure.changesets([%{"species_ids" => ["1"]}])
      
      assert BulkProcedure.unfold_to_attrs(changesets) == []
    end

    test "species are spread apart" do
      {:ok, changesets} = 
        BulkProcedure.changesets([%{"name" => "p",
                               "species_ids" => ["1", "3"],
                               "frequency_id" => "5"}])

      actual = BulkProcedure.unfold_to_attrs(changesets)
      expected = [ %{name: "p", species_id: 1, frequency_id: 5},
                   %{name: "p", species_id: 3, frequency_id: 5} ]
      assert actual == expected
    end
  end
end
