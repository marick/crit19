defmodule CritWeb.Usables.AnimalController.UtilityTest do
  use CritWeb.ConnCase
  alias CritWeb.Usables.AnimalController.Testable


  describe "addition of the institution to params" do

    test "a lone animal" do
      actual = Testable.put_institution(%{}, @institution)
      assert actual == %{"institution" => @institution}
    end

    test "an animal with service gaps" do
      input = %{"service_gaps" => %{"0" => %{}}}
      actual = Testable.put_institution(input, @institution)
      expected = %{"institution" => @institution,
                  "service_gaps" => %{"0" => %{"institution" => @institution}}}
      assert actual == expected
    end
    
  end
  
end
