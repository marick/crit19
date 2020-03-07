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
      |> assert_error(name: "must have at least one species")
    end

    test "there can be a species without a name" do
      # ... so that a single button can select a species for N procedures"
      %Creation{}
      |> Creation.changeset(%{"species_ids" => ["1"]})
      |> assert_valid
    end
  end

  describe "unfolding changesets" do
  end
end
