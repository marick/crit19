defmodule CritBiz.ViewModels.Setup.BulkAnimalValidationTest do
  use Crit.DataCase
  alias CritBiz.ViewModels.Setup, as: VM
  alias Crit.Exemplars.Params.BulkAnimal, as: Params

  @correct %{"names" => "a, b, c",
             "species_id" => to_string(@bovine_id),
             "in_service_datestring" => @iso_date_1,
             "out_of_service_datestring" => @iso_date_2}

  test "success" do
    Params.validate_category(:valid, &become_correct/1)
    Params.validate_category(:invalid, &become_incorrect/1)
  end

  describe "error checking" do
    test "blank datestrings will just retain old values" do
      # The front end should not ever send back blank datestrings, but...
      input = Map.merge(@correct, %{"in_service_datestring" => "",
                                    "out_of_service_datestring" => ""})

      VM.BulkAnimal.accept_form(input, @institution) |> ok_payload
      |> assert_valid
      # This behavior is a happenstance because `cast` doesn't
      # overwrite a non-blank value with a blank one. But seems as good
      # a way to handle an 'impossible' error as any other.
      |> assert_data(in_service_datestring: @today,
                     out_of_service_datestring: @never)
    end

    test "datestrings are checked" do
      input = Map.merge(@correct, %{"in_service_datestring" => @iso_date_4,
                                    "out_of_service_datestring" => @iso_date_3})

      VM.BulkAnimal.accept_form(input, @institution) |> error2_payload(:form)
      |> assert_invalid
      |> assert_error(:out_of_service_datestring)
      |> assert_form_will_display_errors
    end
  end

  # ----------------------------------------------------------------------------

  

  defp become_correct(params) do 
    VM.BulkAnimal.accept_form(params, @institution)
    |> ok_payload
  end

  defp become_incorrect(params) do
    VM.BulkAnimal.accept_form(params, @institution) |> error2_payload(:form)
  end
end
  
