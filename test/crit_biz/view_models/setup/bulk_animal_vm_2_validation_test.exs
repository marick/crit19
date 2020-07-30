defmodule CritBiz.ViewModels.Setup.BulkAnimalValidationTest do
  use Crit.DataCase
  alias Crit.Exemplars.Params.BulkAnimal, as: Params

  test "categories" do
    Params.check_form_validation(categories: [:valid])
    Params.check_form_validation(categories: [:invalid])
  end
end
  
