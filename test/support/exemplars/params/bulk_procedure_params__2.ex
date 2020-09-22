defmodule Crit.Exemplars.Params.BulkProcedures2 do
  alias CritBiz.ViewModels.Setup, as: VM
  alias Crit.Schemas
  use Crit.Params.Variants.SingletonToMany2
  use FlowAssertions

  @moduledoc """
  %{
    "in_service_datestring" => "today",
    "names" => "bad ass animal, animal of bliss",
    "out_of_service_datestring" => "never",
    "species_id" => "1"
  }
  """

  @test_data build(
    # View model changesets
    module_under_test: VM.BulkProcedure,
    produces: Schemas.Procedure,
    validates: [:name, :species_ids, :frequency_id],
      
    lowering_splits: %{:species_ids => :species_id},
    lowering_retains: [:name, :frequency_id],
      
    exemplars: [
      one_species: %{
        categories: [:valid, :filled],
        params: to_strings(%{name: "one species", 
                             species_ids: [@bovine_id],
                             frequency_id: @once_per_week_frequency_id}),
      },
      
      two_species: %{
        categories: [:valid, :filled],
        params: to_strings(%{name: "two species",
                             species_ids: [@bovine_id, @equine_id],
                             frequency_id: @once_per_week_frequency_id}),
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
        params: like(:all_blank, except: %{species_ids: [@bovine_id]}),
        unchanged: [:name],
      },
      
      #-----------------
      # Only one way to be invalid
      name_but_no_species: %{
        categories: [:invalid, :filled],
        params: to_strings(%{name: "xxlxl",
                             frequency_id: @unlimited_frequency_id}),
        unchanged: [:species_ids],
        errors: [species_ids: @at_least_one_species],
      },
    ])
    
  def test_data, do: @test_data

  def that_are(descriptors) when is_list(descriptors),
    do: Variant.that_are(test_data(), descriptors)

  def that_are(descriptor), do: that_are([descriptor])
  def that_are(descriptor, opts), do: that_are([[descriptor | opts]])

  def accept_form(descriptor) do
    that_are(descriptor) |> module_under_test().accept_form()
  end

  def lower_changesets(descriptor) do
    {:ok, vm_changesets} = accept_form(descriptor)
    module_under_test().lower_changesets(vm_changesets)
  end

  def discarded do
    fn result, name ->
      if ok_content(result) != [] do
        flunk("Exemplar #{name} is not supposed to produce a changeset")
      end
    end
  end
end
