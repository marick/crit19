defmodule CritBiz.ViewModels.Setup.ProcedureVM.ValidationTest do
  use Crit.DataCase, async: true
  alias CritBiz.ViewModels.Setup, as: VM

  # ----------------------------------------------------------------------------
  describe "successful form validation" do
    test "validation of one procedure" do
      params = [
        %{"0" =>
           %{"index" => "0",
             "name" => "haltering",
             "species_ids" => [to_string(@bovine_id)],
             "frequency_id" => "32"
            }
         }
      ]

      [only] = VM.BulkProcedure.accept_form(params) |> ok_payload
      only
      |> assert_valid
      |> assert_change(name: "haltering",
                       species_ids: [@bovine_id],
                       frequency_id: 32)
    end
    
  end
end
