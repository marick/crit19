defmodule Crit.Exemplars.Params.BulkAnimal do

  @moduledoc """
  """

  alias CritBiz.ViewModels.Setup, as: VM
  use Crit.Params.OneToManyBuilder,
    module_under_test: VM.BulkAnimal,
    default_cast_fields: [:names, :species_id,
                          :in_service_datestring, :out_of_service_datestring],
    data: %{
      valid: %{
        categories: [:valid],
        params: to_strings(%{names: "a, b, c",
                             species_id: @bovine_id,
                             in_service_datestring: @iso_date_1,
                             out_of_service_datestring: @iso_date_2})
      },
    }

  def accept_form(descriptor) do
    that_are(descriptor) |> module_under_test().accept_form(@institution)
  end
end

