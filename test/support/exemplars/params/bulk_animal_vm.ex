defmodule Crit.Exemplars.Params.BulkAnimal do

  @moduledoc """
  """

  alias CritBiz.ViewModels.Setup, as: VM
  use Crit.Params.Builder,
    module_under_test: VM.BulkAnimal,
    default_cast_fields: [],
    data: %{
      valid: %{
        categories: [:valid],
        params: to_strings(%{names: "a, b, c",
                             species_id: @bovine_id,
                             in_service_datestring: @iso_date_1,
                             out_of_service_datestring: @iso_date_2})
      },
    }
end


