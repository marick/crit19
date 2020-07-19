defmodule Crit.Exemplars.Params do
  alias Crit.Exemplars, as: Ex
  import Crit.Params
  alias Ecto.Changeset
  alias Ecto.ChangesetX
  

  def put_nested(top_params, field, nary) when is_list(nary) do
    param_map = 
      nary
      |> Enum.with_index
      |> Enum.map(fn {lower_params, index} -> {to_string(index), lower_params} end)
      |> Map.new
    %{ top_params | field => param_map}
  end


  # ---------Animal forms -------------------------------------------------------

  @base_vm_animal %{
      "id" => "1",
      "lock_version" => "2",
      "name" => "Bossie",
      "species_name" => "species name",
      "service_gaps" => %{}
  } |> Ex.Datespan.put_datestrings(:widest_finite)

  @service_gaps %{
    empty: %{
      "reason" => "",
      "in_service_datestring" => "",
      "out_of_service_datestring" => "",
    }, 

    first: Ex.Datespan.put_datestrings(%{"reason" => "first reason"}, :first)
  }

  def vm_animal(service_gap_descriptors) do
    service_gaps = 
      service_gap_descriptors
      |> Enum.with_index
      |> Enum.reduce(%{}, fn {descriptor, index}, acc ->
           Map.put(acc, to_string(index), @service_gaps[descriptor])
         end)

      Map.put(@base_vm_animal, "service_gaps", service_gaps)
  end

end
