defmodule Crit.Exemplars.Params.BulkAnimal do

  alias CritBiz.ViewModels.Setup, as: VM
  alias Crit.Schemas
  alias Ecto.Datespan
  alias CritBiz.ViewModels.FieldValidators
  use Crit.Params.Variants.OneToMany

  @moduledoc """
  %{
    "in_service_datestring" => "today",
    "names" => "bad ass animal, animal of bliss",
    "out_of_service_datestring" => "never",
    "species_id" => "1"
  }
  """

  @test_data build(
    module_under_test: VM.BulkAnimal,
    produces: Schemas.Animal,
    validates: [:names,
                :species_id,
                :in_service_datestring, :out_of_service_datestring],
    
    lowering_splits: %{:names => :name},
    lowering_retains: [:species_id],

    exemplars: [
      # -------------------------------------------VALID-------------------
      valid: %{params: to_strings(%{names: "a, b, c",
                                    species_id: @bovine_id,
                                    in_service_datestring: @iso_date_1,
                                    out_of_service_datestring: @iso_date_2}),
               lowering_adds: %{span: Datespan.customary(@date_1, @date_2)},
               categories: [:valid],
              },

      # The front end should not ever send back blank datestrings, but
      # it's worth documenting the behavior if the impossible happens.
      blank_datestrings: %{categories: [:valid],
                           params: like(:valid,
                             except: %{in_service_datestring: "",
                                       out_of_service_datestring: ""}),
                           # The underlying value, which defaults to
                           # "today" and "never", is retained.
                           unchanged: [:in_service_datestring,
                                       :out_of_service_datestring]
                          },

      # ----------------------------------------INVALID-----------------
      
      blank_names: %{
        shows_delegation: {FieldValidators, :namelist},
        params: like(:valid, except: %{names: "  ,"}),
        errors: [names: @no_valid_names_message],
        categories: [:invalid],
      },
      
      out_of_order: %{
        shows_delegation: {FieldValidators, :date_order},
        params: like(:valid,
          except: %{in_service_datestring: @iso_date_4,
                    out_of_service_datestring: @iso_date_3}),
        errors: [out_of_service_datestring: @date_misorder_message],
        categories: [:invalid],
      }
    ])
    
  def test_data, do: @test_data
      
  def accept_form(descriptor) do
    module_under_test = config().module_under_test
    that_are(descriptor) |> module_under_test.accept_form(@institution)
  end

  def lower_changesets(descriptor) do
    {:ok, vm_changeset} = accept_form(descriptor)
    config(:module_under_test).lower_changeset(vm_changeset)
  end
end
