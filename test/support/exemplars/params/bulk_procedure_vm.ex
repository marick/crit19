defmodule Crit.Exemplars.Params.BulkProcedures do

  @moduledoc """
  %{
    "0" => %{"frequency_id" => "32", "index" => "0", "name" => ""},
    "1" => %{
      "frequency_id" => "32",
      "index" => "1",
      "name" => "",
      "species_ids" => ["1"]
    },
    "2" => %{"frequency_id" => "32", "index" => "2", "name" => ""}
  }
  """

  alias CritBiz.ViewModels.Setup, as: VM
  alias Crit.Schemas
  import Crit.Params.Builder, only: [to_strings: 1]
  use Crit.TestConstants
  use Crit.Params.ManyToManyBuilder


  def test_data do
    %{
      # View model changesets
      module_under_test: VM.BulkProcedure,
      default_cast_fields: [:name, :species_ids, :frequency_id],
      
      # Lowering
      # produces: Schemas.Procedure,
      # splits_on: :species_ids,
      # retains: [:name, :frequency_id],
      
      data: %{
        valid: %{
          categories: [:valid, :filled],
          params: to_strings(%{name: "valid", 
                               species_ids: [@bovine_id],
                               frequency_id: @once_per_week_frequency_id}),
        },
        
        two_species: %{
          categories: [:valid, :filled],
          params: to_strings(%{name: "two species",
                               species_ids: [@bovine_id, @equine_id],
                               frequency_id: @once_per_week_frequency_id}),
          fields_copied_to_each: [:name, :frequency_id],
          additions_to_each: %{species_id: [@bovine_id, @equine_id]}
        },
        
        all_blank: %{
          categories: [:valid, :blank],
          params: to_strings(%{name: "", 
                             # no value for species_ids will be sent by the browser.
                               frequency_id: @unlimited_frequency_id}),
          unchanged: [:name, :species_ids],
        },
        
        # Because there's a "click here to select this species in
        # all subforms button, it's valid to have a species chosen,
        # but not a name. But those create nothing in the database.
        blank_with_species: %{
          categories: [:valid, :blank],
          params: to_strings(%{name: "",
                               species_ids: [@bovine_id],
                               frequency_id: @unlimited_frequency_id}),
        },
        
        #-----------------
        # Only one way to be invalid
        name_but_no_species: %{
          params: to_strings(%{name: "xxlxl",
                               frequency_id: @unlimited_frequency_id}),
          unchanged: [:species_ids],
          categories: [:invalid, :filled]
        },
      }
    }
  end

  # ----------------------------------------------------------------------------

  def accept_form(descriptor) do
    that_are(descriptor) |> module_under_test().accept_form
  end
      
  def lower_changesets(descriptor) do
    {:ok, vm_changesets} = accept_form(descriptor)
    module_under_test().lower_changesets(vm_changesets)
  end
end


