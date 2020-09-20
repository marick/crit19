defmodule Crit.Exemplars.Params.BulkProcedures2 do

  use Crit.Errors
  use Crit.TestConstants
  alias CritBiz.ViewModels.Setup, as: VM
  alias Crit.Schemas
  # alias Ecto.Datespan
  # alias CritBiz.ViewModels.FieldValidators
  import Crit.Params.Build
  alias Crit.Params.{Validate,Exemplar}
  alias Crit.Params.Variants.SingletonToMany2, as: Variant
  use FlowAssertions.Define

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

  def module_under_test(), do: test_data().module_under_test

  def that_are(descriptors) when is_list(descriptors),
    do: Variant.that_are(test_data(), descriptors)

  def that_are(descriptor), do: that_are([descriptor])
  def that_are(descriptor, opts), do: that_are([[descriptor | opts]])

  def as_cast(descriptor, opts \\ []),
    do: Exemplar.as_cast(test_data(), descriptor, opts)
  
  def cast_map(descriptor, opts \\ []),
    do: Exemplar.cast_map(test_data(), descriptor, opts)

  def discarded, do: Variant.discarded()

  def check_changeset(result, name),
    do: Variant.check_changeset(test_data(), result, name)

  def accept_form(descriptor) do
    that_are(descriptor) |> module_under_test().accept_form()
  end

  def lower_changesets(descriptor) do
    {:ok, vm_changesets} = accept_form(descriptor)
    module_under_test().lower_changesets(vm_changesets)
  end

  def check_form_validation(opts) do
    opts = Enum.into(opts, %{verbose: false})
    
    check =
      case Map.get(opts, :result) do
        nil ->
          fn result, name -> check_changeset(result, name) end
        f -> f
      end
    
    names = 
      Crit.Params.Get.names_in_categories(test_data(), opts.categories, opts.verbose)
    
    for name <- names do
      Validate.note_name(name, opts.verbose)
      accept_form(name) |> check.(name)
    end
  end

  defchain validate(:form_checking, name, changeset) do 
    Validate.FormChecking.check(test_data(), changeset, name)
  end

  defchain validate(:lowered, name),
    do: Validate.Lowering.check(test_data(), name, lower_changesets(name))
end
