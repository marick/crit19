defmodule Crit.Exemplars.Params.BulkAnimal do

  @moduledoc """
  """

  alias CritBiz.ViewModels.Setup, as: VM
  alias Ecto.Datespan
  use Crit.Params.OneToManyBuilder

  @test_data build(
    module_under_test: VM.BulkAnimal,
    produces: Schemas.Animal,
    validates: [:names,
                :species_id,
                :in_service_datestring, :out_of_service_datestring],
    
    lowering_splits: %{:names => :name},
    lowering_retains: [:species_id],

    exemplars: [
      valid: %{categories: [:valid],
               params: to_strings(%{names: "a, b, c",
                                    species_id: @bovine_id,
                                    in_service_datestring: @iso_date_1,
                                    out_of_service_datestring: @iso_date_2}),
               lowering_adds: %{span: Datespan.customary(@date_1, @date_2)}
              }, 
      
      blank_names: %{categories: [:invalid],
                     params: like(:valid, except: %{names: ""}),
                     unchanged: [:names],
                     errors: [names: @no_valid_names_message]}
    ])
    
  def test_data, do: @test_data
      
  def accept_form(descriptor) do
    module_under_test = config().module_under_test
    that_are(descriptor) |> module_under_test.accept_form(@institution)
  end

  def lower_changesets(descriptor) do
    {:ok, vm_changesets} = accept_form(descriptor)
    config(:module_under_test).lower_changesets(vm_changesets)
  end
end


