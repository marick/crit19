defmodule CritBiz.ViewModels.Setup.BulkAnimalValidationTest do
  use Crit.DataCase
  alias CritBiz.ViewModels.Setup, as: VM
  alias Crit.Exemplars.Params.BulkAnimal, as: Params

  @correct %{"names" => "a, b, c",
             "species_id" => to_string(@bovine_id),
             "in_service_datestring" => @iso_date_1,
             "out_of_service_datestring" => @iso_date_2}

  test "categories" do
    Params.check_form_validation(categories: [:valid])
    Params.check_form_validation(categories: [:invalid])
  end

  describe "error checking" do
    test "datestrings are checked" do
      input = Map.merge(@correct, %{"in_service_datestring" => @iso_date_4,
                                    "out_of_service_datestring" => @iso_date_3})

      VM.BulkAnimal.accept_form(input, @institution) |> error2_payload(:form)
      |> assert_invalid
      |> assert_error(:out_of_service_datestring)
      |> assert_form_will_display_errors
    end
  end
end
  
