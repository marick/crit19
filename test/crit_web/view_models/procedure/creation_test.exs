defmodule CritWeb.ViewModels.Procedure.CreationTest do
  use Crit.DataCase
  alias CritWeb.ViewModels.Procedure.Creation


  describe "checking form attributes" do
    test "both name and species id means validity" do 
      %Creation{}
      |> Creation.changeset(%{"name"=>"x", "species_ids" => ["0"]})
      |> assert_valid
    end
    
    test "both name and species missing also means validity" do 
      %Creation{}
      |> Creation.changeset(%{"name"=>""})
      |> assert_valid
    end
    
    test "if there's a name, there must be a species" do 
      %Creation{}
      |> Creation.changeset(%{"name"=>"procedure"})
      |> assert_invalid
      |> assert_error(species_ids: Creation.legit_error_messages.at_least_one_species)
    end

    test "there can be a species without a name" do
      # ... so that a single button can select a species for N procedures"
      %Creation{}
      |> Creation.changeset(%{"species_ids" => ["1"]})
      |> assert_valid
    end
  end

  describe "changesetS return value" do
    test "on success" do
      input = [%{"name" => "prep", "species_ids" => ["1"]}]
      assert {:ok, [only]} = Creation.changesets(input)
      assert_valid(only)
    end      
    test "on failure" do
      input = [%{"name" => "prep"}]
      assert {:error, [only]} = Creation.changesets(input)
      assert_invalid(only)
    end      
  end

  describe "unfolding changesets" do
    test "ones without names are ignored" do
      {:ok, changesets} = 
        Creation.changesets([%{"species_ids" => ["1"]}])
      
      assert Creation.unfold_to_attrs(changesets) == []
    end

    test "species are spread apart" do
      {:ok, changesets} = 
        Creation.changesets([%{"name" => "p", "species_ids" => ["1", "3"]}])

      actual = Creation.unfold_to_attrs(changesets)
      expected = [ %{name: "p", species_id: 1},
                   %{name: "p", species_id: 3} ]
      assert actual == expected
    end
  end
end
